import crossplane # type: ignore
import pprint # type: ignore
import tempfile # type: ignore
# TODO: disable typing idgas

# /nix/store/4lb0cvvkzzzsk1l6wpfsw136axr4fxlv-nginx-1.28.2/conf/nginx.conf
nginx_conf = machine.succeed("find /nix/store -name '*nginx.conf' -maxdepth 2").strip()
print(nginx_conf)

# TODO: fail if empty
nginx_contents = machine.succeed(f"cat {nginx_conf}")

with tempfile.NamedTemporaryFile(mode="w", suffix=".conf", delete=False) as f:
    f.write(nginx_contents)
    tmp_path = f.name

parsed = crossplane.parse(tmp_path)
top_level = parsed['config'][0]['parsed']

http_block = next(d for d in top_level if d['directive'] == 'http')
server_blocks = [d for d in http_block['block'] if d['directive'] == 'server']

# for debugging
pprint.pp(server_blocks)

assert len(server_blocks) == 2, f"Expected 2 server blocks, got {len(server_blocks)}"

def get_directives(block, name):
    return [d for d in block if d['directive'] == name]

def find_directive(block, directive):
    for d in block:
        if d['directive'] == directive:
            yield d
        if 'block' in d:
            yield from find_directive(d['block'], directive)

# port 80 redirect block
port_80 = next((s for s in server_blocks if any(
    '80' in a for d in s['block'] if d['directive'] == 'listen' for a in d['args']
)), None)
assert port_80 is not None, "Expected a port 80 server block"
returns = list(find_directive(port_80['block'], 'return'))
assert any('301' in d['args'][0] for d in returns), "Expected 301 redirect"

# port 443 SSL block
port_443 = next((s for s in server_blocks if any(
    '443' in a for d in s['block'] if d['directive'] == 'listen' for a in d['args']
)), None)
assert port_443 is not None, "Expected a port 443 server block"
assert any(d['directive'] == 'ssl_certificate' for d in port_443['block']), "Expected ssl_certificate"
assert any(d['directive'] == 'ssl_certificate_key' for d in port_443['block']), "Expected ssl_certificate_key"

# proxy location
locations = get_directives(port_443['block'], 'location')
proxy_location = next((l for l in locations if '/' in l['args'] and '=' not in l['args']), None)
assert proxy_location is not None, "Expected a proxy location block"
proxy_pass = get_directives(proxy_location['block'], 'proxy_pass')
assert len(proxy_pass) == 1, "Expected a proxy_pass directive"
assert proxy_pass[0]['args'][0] == "http://shrike:20031", f"Unexpected proxy_pass: {proxy_pass[0]['args'][0]}"

# healthz location
healthz = next((l for l in locations if '=' in l['args'] and '/healthz' in l['args']), None)
assert healthz is not None, "Expected a /healthz location block"
healthz_return = get_directives(healthz['block'], 'return')
assert len(healthz_return) == 1, "Expected a return directive in /healthz"
assert healthz_return[0]['args'][0] == '200', "Expected 200 return in /healthz"

# no easy way to find it, it's not exposed. we can try the repl
# nix --extra-experimental-features "flakes" repl
# :lf .
# nixosConfigurations.adler.config.services.nginx.<tab>
import crossplane # type: ignore
import pprint # type: ignore
import tempfile # type: ignore
# TODO: disable typing idgas

# /nix/store/4lb0cvvkzzzsk1l6wpfsw136axr4fxlv-nginx-1.28.2/conf/nginx.conf
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

from collections import defaultdict

def get_directives(block, name):
    return [d for d in block if d['directive'] == name]

def find_directive(block, directive):
    for d in block:
        if d['directive'] == directive:
            yield d
        if 'block' in d:
            yield from find_directive(d['block'], directive)

def get_server_name(block):
    names = get_directives(block, 'server_name')
    return names[0]['args'][0] if names else None

# group server blocks by server_name
blocks_by_service = defaultdict(list)
for block in server_blocks:
    name = get_server_name(block['block'])
    if name:
        blocks_by_service[name].append(block)

def assert_service(service_name, proxy_pass, extra_config_check=None):
    fqdn = f"{service_name}.stanley.arpa"
    blocks = blocks_by_service[fqdn]
    assert len(blocks) == 2, f"{service_name}: Expected 2 server blocks, got {len(blocks)}"

    port_80 = next((s for s in blocks if any(
        '80' in a for d in s['block'] if d['directive'] == 'listen' for a in d['args']
    )), None)
    assert port_80 is not None, f"{service_name}: Expected port 80 block"
    returns = list(find_directive(port_80['block'], 'return'))
    assert any('301' in d['args'][0] for d in returns), f"{service_name}: Expected 301 redirect"

    port_443 = next((s for s in blocks if any(
        '443' in a for d in s['block'] if d['directive'] == 'listen' for a in d['args']
    )), None)
    assert port_443 is not None, f"{service_name}: Expected port 443 block"
    assert any(d['directive'] == 'ssl_certificate' for d in port_443['block']), f"{service_name}: Expected ssl_certificate"
    assert any(d['directive'] == 'ssl_certificate_key' for d in port_443['block']), f"{service_name}: Expected ssl_certificate_key"

    locations = get_directives(port_443['block'], 'location')
    proxy_location = next((l for l in locations if '/' in l['args'] and '=' not in l['args']), None)
    assert proxy_location is not None, f"{service_name}: Expected proxy location"
    proxy_pass_directives = get_directives(proxy_location['block'], 'proxy_pass')
    assert len(proxy_pass_directives) == 1, f"{service_name}: Expected proxy_pass"
    assert proxy_pass_directives[0]['args'][0] == proxy_pass, \
        f"{service_name}: Expected proxy_pass {proxy_pass}, got {proxy_pass_directives[0]['args'][0]}"

    healthz = next((l for l in locations if '=' in l['args'] and '/healthz' in l['args']), None)
    assert healthz is not None, f"{service_name}: Expected /healthz location"
    healthz_return = get_directives(healthz['block'], 'return')
    assert healthz_return[0]['args'][0] == '200', f"{service_name}: Expected 200 in /healthz"

    if extra_config_check:
        extra_config_check(port_443)

# per-service assertions
assert len(server_blocks) == 4, f"Expected 4 server blocks, got {len(server_blocks)}"

assert_service("rtx", "http://10.92.8.4:20031")

def check_demucs_extra(port_443):
    extra = list(find_directive(port_443['block'], 'client_max_body_size'))
    assert any(d['args'][0] == '256m' for d in extra), "demucs: Expected client_max_body_size 256m"

assert_service("demucs", "http://10.92.8.6:20032", extra_config_check=check_demucs_extra)

# no easy way to find it, it's not exposed. we can try the repl
# nix --extra-experimental-features "flakes" repl
# :lf .
# nixosConfigurations.adler.config.services.nginx.<tab>

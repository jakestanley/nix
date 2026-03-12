machine.wait_for_unit("dnsmasq.service")

# print the unit so we can find where it's set
print(machine.succeed("systemctl cat dnsmasq.service"))

# we actually need to find the file, find /etc/dnsmasq.d didn't work first time round
print(machine.succeed("find /etc/ -name '*.conf' | grep -i dnsmasq"))

# check the content of dnsmasq-conf.conf
print(machine.succeed(f'cat {dnsmasq_conf}'))

# check conf-dir is set in dnsmas-conf.conf
# machine.succeed(f'cat {dnsmasq_conf} | grep -i "^conf-dir=/etc/dnsmasq.d/,\*.conf"')

machine.succeed("dig @127.0.0.1 adler.stanley.arpa | grep 10.66.6.6")
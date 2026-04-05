# Troubleshooting

## No audio after display sleep/wake

WirePlumber can lose track of the HDMI audio device when the display powers off. A WirePlumber config (`session.suspend-timeout-seconds = 0`) is set to prevent this, but if audio is lost, restart WirePlumber to recover:

```sh
systemctl --user restart wireplumber
```

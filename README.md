# matrix-telegram-bridge
Matrix - Telegram bridge bot

## About
This bridge can relay [Telegram](https://telegram.me) messages to an [Matrix](https://matrix.org) chatroom.

## Deploy
Execute:

```bash
cake build # Build the source (CoffeeScript -> JavaScript)
```

After that, make sure to set some values defined in `config.example.json`, and rename it to `config.json`.

Then run:

```bash
cake start # Start the bridge
```

## FAQ
TODO

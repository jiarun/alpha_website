# Alpha Ry Website

Static website for Alpha Ry, covering badminton, cricket, and events.

## Project Structure

- `website/index.html` - main sport selection page
- `website/badminton/index.html` - badminton coaching page
- `website/cricket/index.html` - cricket coaching page
- `website/events/index.html` - events page
- `website/css/shared.css` - shared styles
- `website/js/shared.js` - shared language, menu, form, and gallery behavior
- `website/images/` - website image assets

## Local Preview

From the project root:

```sh
python3 -m http.server 8080 --directory website
```

Then open:

```text
http://localhost:8080
```

## Deploy

The included deploy script syncs the static website folder to AWS S3:

```sh
./deploy.sh <bucket-name>
```

If no bucket name is provided, the script uses `smashkids-website`.

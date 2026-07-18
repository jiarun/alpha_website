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

The included deploy script syncs the static website folder to GoDaddy/cPanel over FTP or FTPS.

Create a local deployment config:

```sh
cp .env.deploy.example .env.deploy
```

Edit `.env.deploy` with the GoDaddy/cPanel FTP details, then test the deployment plan:

```sh
./deploy.sh --dry-run
```

Deploy:

```sh
./deploy.sh
```

The `.env.deploy` file is ignored by Git and should not be committed.

### Automatic Deploys From GitHub

The GitHub Actions workflow in `.github/workflows/deploy-godaddy.yml` deploys after every push to `main`.

Add these GitHub repository secrets before using it:

- `CPANEL_FTP_HOST`
- `CPANEL_FTP_USER`
- `CPANEL_FTP_PASSWORD`
- `CPANEL_REMOTE_DIR`, use `public_html/alphary.org`
- `CPANEL_FTP_PORT`, usually `21`
- `CPANEL_FTP_SSL`, usually `true`

Use the exact FTP server shown in GoDaddy/cPanel. In cPanel, open **FTP Accounts**, then choose **Configure FTP Client** for the FTP user. The FTP server may be a GoDaddy server name, not `ftp.alphary.org`.

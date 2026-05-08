# GitHub Pages Deployment

## What This Publishes

The GitHub Pages workflow publishes the `Website` folder.

Public paths:

- `https://moneymuncher.ca/` redirects to `/kids/`
- `https://moneymuncher.ca/kids/` shows the kids landing page
- `https://moneymuncher.ca/kids/play/` hosts the Unity WebGL build

## First-Time GitHub Setup

1. Create a GitHub repository.
2. Push this project to the repository's `main` branch.
3. In GitHub, go to `Settings > Pages`.
4. Set Source to `GitHub Actions`.
5. Add the custom domain `moneymuncher.ca`.
6. Configure DNS with your domain provider according to GitHub Pages' custom domain instructions.

## Build And Publish

1. In Unity, click `Money Muncher > Build Campaign Levels`.
2. In Unity, click `Money Muncher > Build Kids WebGL`.
3. The WebGL build appears in `Website/kids/play`.
4. Commit and push to `main`.
5. GitHub Actions deploys the `Website` folder.

## Important

The Unity WebGL output in `Website/kids/play` should be committed when you are ready to publish. GitHub Pages will serve those generated files directly.

# 🚀 GitHub Pages Deployment Guide

This project is configured for easy deployment to GitHub Pages using two methods:

## Method 1: Automatic Deployment (Recommended)

### Setup (One-time)
1. **Push your code to GitHub:**
   ```bash
   git add .
   git commit -m "Add GitHub Pages deployment"
   git push origin main
   ```

2. **Enable GitHub Pages:**
   - Go to your repository on GitHub
   - Navigate to **Settings** → **Pages**
   - Under **Source**, select **GitHub Actions**
   - The workflow will automatically deploy on every push to main/master

### How it Works
- **Automatic builds** on every push to main/master branch
- **Uses GitHub Actions** with the workflow in `.github/workflows/deploy.yml`
- **Deploys to** `https://yourusername.github.io/fake3d/`
- **Zero configuration** required after initial setup

## Method 2: Manual Deployment

### Prerequisites
```bash
npm install  # Install dependencies including gh-pages
```

### Deploy Command
```bash
npm run deploy
```

This will:
1. Build the project for production
2. Deploy the `dist` folder to the `gh-pages` branch
3. Make it available at `https://yourusername.github.io/fake3d/`

## 🔧 Configuration Details

### Vite Configuration
- **Base path** automatically set to `/fake3d/` for production
- **Assets** properly configured for GitHub Pages
- **Modern build target** (ES2022) for optimal performance

### Build Process
- **TypeScript compilation** with type checking
- **GLSL shader bundling** via vite-plugin-glsl
- **Asset optimization** and minification
- **Source maps** for debugging

## 🌐 Live URL
After deployment, your site will be available at:
```
https://yourusername.github.io/fake3d/
```

Replace `yourusername` with your actual GitHub username.

## 📱 Features on GitHub Pages
- ✅ **WebGL support** in all modern browsers
- ✅ **Device orientation** on mobile devices (with permission)
- ✅ **Responsive design** for all screen sizes
- ✅ **Fast loading** with optimized assets
- ✅ **HTTPS** by default on GitHub Pages

## 🔍 Troubleshooting

### If deployment fails:
1. Check that GitHub Pages is enabled in repository settings
2. Ensure the workflow has proper permissions
3. Verify the build completes successfully locally: `npm run build`

### If the site doesn't load:
1. Check the browser console for errors
2. Ensure WebGL is supported and enabled
3. Try a different modern browser (Chrome, Firefox, Safari, Edge)

## 🎯 Performance Tips
- The site uses **modern ES2022** features for optimal performance
- **WebGL shaders** are optimized for smooth 60fps rendering
- **Images are optimized** but you can further compress them if needed
- **Device pixel ratio** is capped at 2x to prevent performance issues on high-DPI displays

# Instructions for Render Deployment

## 🚀 Deploy to Render

### Option 1: Using Render Dashboard (Recommended)

1. **Go to Render Dashboard**: https://dashboard.render.com
2. **Connect your GitHub repository**
3. **Create New Web Service**
4. **Configure Service**:
   - **Name**: Veritas
   - **Branch**: main
   - **Root Directory**: ./
   - **Runtime**: Node 20
   - **Build Command**: `npm run build`
   - **Start Command**: `npm start`
   - **Dockerfile Path**: `./Dockerfile.render`

### Option 2: Using Render YAML

1. **Push to GitHub** with the new files
2. **Render will auto-detect** the `render.yaml` file
3. **Configure environment variables** in Render dashboard

### 🔧 Configuration Files Created

- `Dockerfile.render` - Simplified Dockerfile without Rust compilation
- `render.yaml` - Render service configuration
- `.dockerignore` - Optimized for faster builds

### 📋 Environment Variables for Render

Set these in your Render dashboard:
- `NODE_ENV=production`
- `PORT=3000`
- `DOCKER=true`
- Add any API keys or secrets needed

### 🏗️ Build Process

The simplified Dockerfile:
- ✅ Builds frontend and documentation
- ✅ Skips problematic Rust compilation
- ✅ Deploys Node.js application
- ✅ Includes all source code for reference

### 📝 Notes

- Contract compilation can be done locally and committed
- Focus on web application deployment first
- Smart contracts can be deployed separately to StarkNet

### 🔄 Next Steps

1. Push changes to GitHub
2. Configure service in Render
3. Monitor deployment logs
4. Test the deployed application

The application should deploy successfully without Rust compilation errors!

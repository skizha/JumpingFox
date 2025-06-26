# 🚀 Getting Started with GitHub

This guide will help you push the JumpingFox API to a new GitHub repository and set up CI/CD.

## 📋 Prerequisites

- Git installed on your machine
- GitHub account
- Azure subscription (for deployment)

## 🔧 Setup Instructions

### 1. Initialize Git Repository

```powershell
# Navigate to the project directory
cd "c:\Sanjesh\Code\azure\JumpingFox"

# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: JumpingFox API for APIM rate limiting testing"
```

### 2. Create GitHub Repository

1. **Go to GitHub.com** and create a new repository
2. **Repository name**: `jumpingfox-api` (or your preferred name)
3. **Description**: "JumpingFox API - A .NET 8 Web API for testing Azure API Management rate limiting features"
4. **Public/Private**: Choose based on your preference
5. **Don't initialize** with README, .gitignore, or license (we already have them)

### 3. Connect Local Repository to GitHub

```powershell
# Add GitHub remote (replace with your repository URL)
git remote add origin https://github.com/yourusername/jumpingfox-api.git

# Push to GitHub
git branch -M main
git push -u origin main
```

## 🔄 CI/CD Setup

### GitHub Actions (Automatic)

The repository includes two GitHub Actions workflows:

1. **`.github/workflows/main.yml`** - Build, test, and deploy to Azure App Service
2. **`.github/workflows/docker.yml`** - Build and push Docker images

### Required GitHub Secrets

To enable deployments, add these secrets to your GitHub repository:

1. **Go to your GitHub repository**
2. **Settings → Secrets and variables → Actions**
3. **Add the following secrets:**

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `AZUREAPPSERVICE_PUBLISHPROFILE` | Azure App Service publish profile | Download from Azure portal |
| `AZUREAPPSERVICE_PUBLISHPROFILE_STAGING` | Staging slot publish profile | Download from Azure portal (optional) |

### Getting Azure Publish Profile

1. Go to your **Azure App Service** in the portal
2. Click **Get publish profile** in the overview
3. Copy the entire XML content
4. Paste it as the secret value in GitHub

## 📁 Repository Structure

```
JumpingFox/
├── .github/
│   └── workflows/           # GitHub Actions CI/CD
├── Controllers/             # API Controllers
├── Models/                 # Data Models
├── Services/               # Business Logic
├── Properties/             # Launch settings
├── .gitignore             # Git ignore rules
├── Dockerfile             # Container configuration
├── README.md              # Project documentation
├── QUICKSTART.md          # Quick start guide
├── deploy.ps1             # Azure deployment script
├── test-rate-limits.ps1   # Testing script
└── apim-policies-samples.xml # APIM policy examples
```

## 🌟 Next Steps

1. **Push to GitHub** using the commands above
2. **Set up Azure resources** using `deploy.ps1`
3. **Configure GitHub secrets** for automated deployments
4. **Import API to APIM** and configure rate limiting policies
5. **Test rate limits** using the provided testing scripts

## 🔗 Useful Git Commands

```powershell
# Check status
git status

# Create and switch to new branch
git checkout -b feature/new-endpoint

# Commit changes
git add .
git commit -m "Add new rate limiting endpoint"

# Push changes
git push origin main

# Pull latest changes
git pull origin main

# View commit history
git log --oneline
```

## 🆘 Troubleshooting

**Authentication issues?**
- Use GitHub CLI: `gh auth login`
- Or use personal access token instead of password

**Large files?**
- Check `.gitignore` is working properly
- Use `git status` to see what's being tracked

**Build failures in GitHub Actions?**
- Check the Actions tab in your GitHub repository
- Verify all required secrets are set
- Check Azure resource names match the workflow

## 📞 Support

- **Issues**: Use GitHub Issues for bug reports
- **Discussions**: Use GitHub Discussions for questions
- **Wiki**: Add documentation to the GitHub Wiki

---

Ready to push to GitHub? Follow the setup instructions above! 🚀

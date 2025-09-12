# Developer's Deployment Guide

### 📌 Steps to Deploy:

1.  **Push your code to the repository**  
    ✅ _This will automatically trigger the CI/CD pipeline._
    
2.  **Monitor the pipeline:**
    
    -   Navigate to your deployment branch → `Build` → `Pipelines`
        
    -   ✅ All stages of the most recent pipeline should be **green (passed)**
        
    -   ❌ If any stage is marked **red (failed)**, click on it to review the error
        
3.  **Automatic Deployment:**
    
    -   The deployment will be rolled out automatically within **4 minutes**
        
    -   Your application should be live shortly
        
4.  **Manual/Forceful Deployment (if needed):**
    
    -   Go to the **Argo CD UI** and log in
        
    -   Click on the **Sync** button for the `quickops` project → Click **Synchronize**
        
    -   ✅ The application status should change from `Syncing` → `Synced`
        
5.  **Check Application Logs:**
    
    -   Click on the `quickops` application in Argo CD
        
    -   Open the sidebar
        
    -   Filter by `KINDS` → Select **Deployment**
        
    -   You will see a list of deployments
        
    -   Click on a deployment to view logs
        
    -   ▶️ Click the **Follow** button (under the Summary) to stream live logs
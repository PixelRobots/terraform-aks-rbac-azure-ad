# Create a RBAC Azure Kubernetes Services (AKS) cluster with Azure Active Directory using Terraform

In this article I am going to show you how to build a Role Based Access Controlled (RBAC) Azure Kubernetes Services (AKS) cluster using Terraform and Azure Active Directory. At the time of writing this article, when you create an AKS cluster using the portal or terraform RBAC is disabled by default. Luckily since version 1.19.0 of the AzureRM Terraform provider RBAC is supported.   
&nbsp;   
You can find all the files used at the following GitHub repository.   
&nbsp; 
## Prerequisites   
&nbsp;   
Before you can set up your new AKS cluster you need to make sure you have terraform installed on your local machine and it set up correctly. You can find out how to do that using this guide. [https://learn.hashicorp.com/terraform/getting-started/install.html][1]   
&nbsp;   
You will also need a **Service Principal.** You can read my article, First look at terraform ([https://pixelrobots.co.uk/2018/11/first-look-at-terraform-and-the-azure-cloud-shell/][2]) to get this. Make sure you take note of the App ID (**Client ID)**  and Password (**Client Secret)** , we will need them for the variables.tf file later.   
&nbsp;   
An Azure **Storage account**  with a container and an **Access Key**  to store your Terraform state file. How to do this using this guide from Microsoft. [https://pixelrobots.co.uk/2019/01/how-to-store-your-terraform-state-file-in-azure-storage/][3]   
&nbsp;   
An SSH certificate for the Linux VMs for your AKS cluster. You can read more about creating them here. [https://docs.microsoft.com/en-us/azure/virtual-machines/linux/ssh-from-windows][4]. Just make sure you have it saved in the same path that&#39;s stated in the variables terraform file.   
&nbsp;   
&nbsp;   
&nbsp; 
## Creating the Azure Active Directory applications   
&nbsp;   
AKS with RBAC needs two applications created in Azure AD. The first one is a **Server**  application, the second is a **client**  application. We will use the Azure portal to create them.   
&nbsp;   
>Note:   
You can use the same **Server**  application for multiple AKS clusters, but it is recommended to use one **Client**  application per cluster.   
&nbsp;
## Create the Server application   
&nbsp;   
This application is used to get a users Azure AD group membership.   
&nbsp;   
In the Azure Portal navigate to **Azure Active Directory**  and then click on **App registrations**  and click **New application registration** .   
&nbsp;   
[![clip_image001.png][5]][5]   
&nbsp;   
In here we need to enter a **Name**  and make sure **the Application type**  is Web app / API. In the Sign-on URL enter any web address. I am using my domain name. Then click **Create** .   
&nbsp;   
[![clip_image002.png][6]][6]   
&nbsp;   
&nbsp;   
In the new blade click on **Manifest** .   
&nbsp;   
[![clip_image003.png][7]][7]   
&nbsp;   
&nbsp;   
In here we need to edit the **groupMembershipClaims**  value to **&quot;All&quot;** . Make sure to include the &quot;. Then click **Save** .   
&nbsp;   
[![clip_image004.png][8]][8]   
&nbsp;   
Now Click on **Settings**  and then click on **Keys** .   
&nbsp;   
[![clip_image005.png][9]][9]   
&nbsp;   
Now enter a **Description**  for the key and select when you would like it to **Expire** . Then click **Save** .   
&nbsp;   
[![clip_image006.png][10]][10]   
&nbsp;   
Take a copy of the **Value** . We will need it later when we create the AKS cluster. The value is referred to as the **Server application secret** .    
&nbsp;   
>Warning:   
You will not be able to get this value again if you leave this blade. Make sure you copy it.  

 
&nbsp;   
Now click on **Required permissions**  In this blade click on **+ add** .   
&nbsp;   
[![clip_image007.png][11]][11]   
&nbsp;   
Click **Select an API**  then **Microsoft Graph,** then click **Select** .   
&nbsp;   
[![clip_image008.png][12]][12]   
&nbsp;   
Under **Application permissions**  put a tick next **to Read Directory Data** .    
&nbsp;   
[![clip_image009.png][13]][13]   
&nbsp;   
Scroll down further to **Delegated permissions** . Under here put a tick next to **Sign in and read user profile** . Then click **Select** . In the next blade click **Done.**    
&nbsp;   
[![clip_image010.png][14]][14]   
&nbsp;   
Now we have to **Grant admin consent** . All we a have to do is click the button.   
&nbsp;   
[![clip_image011.png][15]][15]   
&nbsp;   
Click **Yes.**    
&nbsp;   
[![clip_image012.png][16]][16]   
&nbsp;   
&nbsp;   
Take a note of the **Application** ID we will need it for later.   
&nbsp;   
[![clip_image013.png][17]][17]   
&nbsp; 
## Create the Client application   
&nbsp;   
This application is used when logging in using the Kubectl the Kubernetes CLI.   
&nbsp;   
Navigate back to the **Azure Active Directory** blade again and click on **App registrations** . Create a new one again.   
&nbsp;   
Enter a **Name** and then under **Application type**  select Native. Add **a Redirect URI**  again I have used my domain. Then click **Create.**    
&nbsp;   
[![clip_image014.png][18]][18]   
&nbsp;   
Now click on **Settings**  and click **Required permissions** . In here click on **Add.**    
&nbsp;   
[![clip_image015.png][19]][19]   
&nbsp;   
Click on **Select an** API. In the search box enter the name of the **Server application**  we just created. Click it and then click **Select** .   
&nbsp;   
[![clip_image016.png][20]][20]   
&nbsp;   
Put a tick next to **Access AKSRBAC.** (the AKSRBAC is your server application name.) Then click **Select** . IN the next blade click **Done.**    
&nbsp;   
[![clip_image017.png][21]][21]   
&nbsp;   
Now we have to **Grant admin consent** . All we a have to do is click the button and then click **Yes.**    
&nbsp;   
[![clip_image018.png][22]][22]   
&nbsp;   
Now take a note of the **Application ID.**  This will be the **Client application ID.**    
&nbsp;   
[![clip_image019.png][23]][23]   
&nbsp; Get the Tenant ID   
&nbsp;   
Now we need to get the Tenant ID. This is easy. Just go back to **Azure Active Directory**  in the Azure portal and click on **Properties** . In here you will see the **Tenant ID** .   
&nbsp;   
[![clip_image020.png][24]][24]   
&nbsp;   
You should now have a set of IDs like the ones I do below.   
&nbsp;   
```
Server application secret: rfHXIJmz6d9/sTHQk4ekyvescN7PcogFyIVmYytmxBs=   
Server Application ID: c59c8bf4-c1be-46a5-992a-18efdd9b08ac   
Client Application ID: 9418f3aa-7845-4de8-90bf-0231ad06450b   
Tenant ID: d8171bb5-a0de-40a6-afdf-8b569cf6dbb8  
``` 
&nbsp;   
&nbsp;
## Deploying the Cluster with Terraform.   
&nbsp;   
Now its time to deploy the AKS cluster using terraform.    
&nbsp;   
First we need to edit the **variables.tf** file from the GitHub repo with the right names and values for your environment. We will need to also add our IDs we have from above along with our **Service Principal**  details.   
&nbsp;   
Now its time to initialize Terraform. First, we need to update the backend.tfvars file with our storage account details for the tfstate file. You should have all this information if you followed the guide in the prerequisites. To actually initialize terraform in your VS Code Bash terminal or Windows subsystem for Linux terminal type the following. Just make sure you're in the directory with the terraform files.   
&nbsp;   
You will need to login to your Azure subscription first use:   
&nbsp;   
`az login `  
&nbsp;      
&nbsp;   
`terraform init -backend-config=backend.tfvars`   
&nbsp;   
[![clip_image022.png][26]][26]   
&nbsp;   
Lets test our Terraform files to see what will happen. We use the plan option for this.   
&nbsp;   
`terraform plan -out "out.plan"`   
&nbsp;   
[![clip_image023.png][27]][27]   
&nbsp;   
Everything looks good. 4 items are going to be created. Now its time to actually apply the configuration. To do that just run:   
&nbsp;   
`terraform apply "out.plan" `  
&nbsp;   
Its going to take some time to build everything. Maybe 20 minutes or more. You might want to go get a cup of tea.   
&nbsp;   
[![clip_image024.png][28]][28]   
&nbsp;
## Configuring Kubernetes RBAC   
&nbsp;   
That&#39;s the cluster deployed! Now its time for us to configure RBAC. To do this we need to create Cluster Role Binding and a Cluster Role using a yaml file. But first we need to connect to Kubernetes cluster as an admin. Use the following command to do that. Just change the **resource group** and **name**  to match yours.   
&nbsp;   
`az aks get-credentials --resource-group pixelrobots-tst-aks --name pixelrobots-tst-aks --admin `  
&nbsp;   
[![clip_image025.png][29]][29]   
&nbsp;   
In the Git repo under the k8s folder you will find two yaml files one to add a user the other for a group. The user one is easy. You just change the email address at the bottom. For the group one you will need to go into Azure AD and get the Group **Object ID** . Once you have the .yaml file you want to use ready. Make sure your in the directory with the files and then type the following to apply it.   
&nbsp;   
`kubectl apply -f rbac-aad-group.yaml   `

&nbsp;   
[![clip_image026.png][30]][30]   
&nbsp;
## Connect to the cluster using RBAC   
&nbsp;   
Now that we have configured the cluster for RBAC its time to connect to it. Lets get some non admin credentials first.   
&nbsp;   
`az aks get-credentials --resource-group pixelrobots-tst-aks --name pixelrobots-tst-aks   `

&nbsp;   
Lets use the kubectl to see what nodes we have.   
&nbsp;   
`kubectl get nodes   `

&nbsp;   
You will notice it is asking us to sign in to the azure portal. Go ahead and do it.   
&nbsp;   
[![clip_image027.png][31]][31]   
&nbsp;   
As you can see you can see the two nodes in the cluster. And that&#39;s it. You now have an RBAC AKS cluster. If you have any questions please reach out.   
&nbsp;     

[1]: https://learn.hashicorp.com/terraform/getting-started/install.html
[2]: https://pixelrobots.co.uk/2018/11/first-look-at-terraform-and-the-azure-cloud-shell/
[3]: https://pixelrobots.co.uk/2019/01/how-to-store-your-terraform-state-file-in-azure-storage/
[4]: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/ssh-from-windows
[5]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-568.png "clip_image001.png"
[6]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-569.png "clip_image002.png"
[7]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-570.png "clip_image003.png"
[8]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-571.png "clip_image004.png"
[9]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-572.png "clip_image005.png"
[10]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-573.png "clip_image006.png"
[11]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-574.png "clip_image007.png"
[12]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-575.png "clip_image008.png"
[13]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-576.png "clip_image009.png"
[14]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-577.png "clip_image010.png"
[15]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-578.png "clip_image011.png"
[16]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-579.png "clip_image012.png"
[17]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-580.png "clip_image013.png"
[18]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-581.png "clip_image014.png"
[19]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-582.png "clip_image015.png"
[20]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-583.png "clip_image016.png"
[21]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-584.png "clip_image017.png"
[22]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-585.png "clip_image018.png"
[23]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-586.png "clip_image019.png"
[24]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-587.png "clip_image020.png"
[25]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-588.png "clip_image021.png"
[26]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-589.png "clip_image022.png"
[27]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-590.png "clip_image023.png"
[28]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-591.png "clip_image024.png"
[29]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-592.png "clip_image025.png"
[30]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-593.png "clip_image026.png"
[31]: https://pixelrobots.co.uk/wp-content/uploads/2019/01/Snip-594.png "clip_image027.png"
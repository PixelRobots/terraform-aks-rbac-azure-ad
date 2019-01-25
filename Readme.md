## Create aks using terraform.   
&nbsp;   
Update the variables file to make sure all is ok.  
&nbsp;   
Then in powershell window type:   
&nbsp;   
```poweshell 
terraform plan 
```   
&nbsp;   
Once finished type   
&nbsp; 
```poweshell   
terraform apply   
```
&nbsp;   
Once it has finished you will have an aks cluster in Azure.   
&nbsp;  
**Now update it!**    
&nbsp; 
## Start up helm   
&nbsp;   
This has to be done in the cloud shell. First connect to cluster.   
&nbsp;   
```
az aks get-credentials --resource-group rabbit-tst-aks --name rabbit-tst-aks 
```  
&nbsp;   
```
kubectl create serviceaccount --namespace kube-system tiller   
```
&nbsp;   
```
kubectl apply -f .\helm-rbac.yaml   
```
&nbsp;   
```
helm init --service-account tiller   
```
&nbsp;   
```
helm repo update   
```
&nbsp;   
&nbsp; 
## Connect to cluster   
&nbsp;   
In VS Code   
&nbsp;   
```
az login   
```
&nbsp; 
```  
az aks get-credentials --resource-group rabbit-tst-aks --name rabbit-tst-aks   
```
&nbsp; 
## Setup the ingress controller   
&nbsp;   
```
kubectl apply -f [https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml][1]   
```
&nbsp;   
```
kubectl apply -f .\cloud-generic.yaml   
```
&nbsp; 
## Setup DNS   
&nbsp;   
External on Azure DNS   
Internal on AD DNS   
&nbsp; 
## Deploy RabbitMQ   
&nbsp;   
To setup the rabbit cluster type   
&nbsp;   
```
kubectl apply -f .\rabbitmq.yaml   
```
&nbsp;   
Once finished type the following to configure rbac.   
&nbsp;   
```
kubectl apply -f .\rabbitmq_rbac.yaml   
```
&nbsp; 
## Deploy Ingress config   
&nbsp;   
```
kubectl apply -f .\Ingress.yaml   
```
&nbsp;   
&nbsp; 
## Deploy Cert Manager   
&nbsp;   
Back in the Cloud Shell   
&nbsp;   
```
helm install --name cert-manager --namespace kube-system stable/cert-manager --set ingressShim.defaultIssuerKind=ClusterIssue
```
&nbsp;   
&nbsp;   
&nbsp; 
## Configure SSL Issuer   
&nbsp;
```   
kubectl apply -f .\Issuer.yaml   
```
&nbsp;   
```
kubectl apply -f .\CertificateObtain.yaml   
```
&nbsp;   
&nbsp;   
&nbsp;   
&nbsp; 
## Troubleshooting   
&nbsp;   
If the cert is not showing you can check the status using:   
&nbsp;   
kubectl describe certificate cloud-trade-com     

[1]: https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/mandatory.yaml
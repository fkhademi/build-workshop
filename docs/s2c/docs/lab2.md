# Lab 2

## Build
Lab time: ~45 minutes

Let’s go build out the connectivity for our app!

![Lab Overview](images/lab-before.png)
_Fig. Lab Overview_

## Lab 2.1 - Connect On-Prem to Azure
Your on-prem Network team has already configured an IPSEC tunnel from the Data Center to your Aviatrix Transit Gateway deployed in the Azure Transit VNET.  You now need to configure the tunnel from Azure to On-Prem.
### Description
Create a Site2Cloud Connection
### Validate
Log in to the Aviatrix Controller and navigate to **_Multi-Cloud Transit -> Setup --> Attach_**.  Scroll down to **_External Connection_**, select **External Device**, **BGP** and **IPSEC**.  

Enter the following fields:

|  |  |
| ------ | ----------- |
| **Transit VPC Name** | azure-transit… |
| **Connection Name** | azure-to-on-prem |
| **Aviatrix Transit Gateway BGP ASN** | 65[pod#] _For Pods 1-9, double pad the pod# with an additional 0 (ie. 65004) and for Pods 10-99 single pad (ie. 65010)_ |
| **Algorithms** | Leave unchecked to select default values |
| **BGP Remote AS Number** | 65000 |
| **Remote Gateway** | <ip-address> _Please resolve the FQDN onprem-gw.aviatrixlab.com_ |
| **Pre-shared Key** | mapleleafs |
| **Local Tunnel IP** | 169.254.[pod#].2/30 |
| **Remote Tunnel IP** | 169.254.[pod#].1/30 |

### Expected Results
After 2 minutes, you should see the tunnel come up.  Scroll down the left side menu, select Site2Cloud and select Setup  
![Site2Cloud](images/site2cloud.png)  
_Fig. Site2Cloud_  

Have a look at Co-Pilot Topology as well.  Double-Click the azure-transit blue node to open it up – you should see the Site2Cloud connection being green here as well.  

![Topology](images/topology-s2c.png)  
_Fig. Topology_  

## Lab 2.2 - Create a Transit VPC in AWS
### Description
All of the VPCs and VNETs in this lab were already created for you, with the exception of the AWS Transit VPC.  Let’s look at how you can use the Aviatrix Controller to create this VPC.
### Validate
* Log in to the Aviatrix Controller
* Scroll down on the left-hand pain to **_Useful Tools -> Create a VPC_**  

![Create a VPC](images/create-a-vpc.png)  
_Fig. Create a VPC_  

* Click **Add New** and enter the following fields:

|  |  |
| ------ | ----------- |
| **Cloud Type** | AWS |
| **Account Name** | aws-account |
| **Gateway Name** | aws-transit |
| **Region** | us-east-1 |
| **VPC CIDR** | 10.[pod#].48.0/20 |
| **Aviatrix Transit VPC** | true |

![Create a VPC](images/create-a-vpc2.png)  
_Fig. Create a VPC_  

### Expected Results
The Transit VPC, Subnets in each AZ, Route Tables, and Internet Gateway will be created in AWS.

## Lab 2.3 - Deploy an Aviatrix Transit Gateway in AWS
### Description
Most of the Gateways have been pre-deployed for you, with the exception of the Transit Gateway in the AWS Transit VPC.  The Aviatrix Controller handles the deployment and lifecycle of the Aviatrix Gateways for you.  
### Validate
* Navigate to **_Multi-Cloud Transit -> Setup -> Transit -> Launch an Aviatrix Transit Gateway_**  

![Screenshot](images/screenshot-transit.png)  
_Fig. Screenshot_  

* Enter the following fields:

|  |  |
| ------ | ----------- |
| **Cloud Type** | AWS |
| **Gateway Name** | aws-transit-gw |
| **Access Account** | aws-account |
| **Region** | us-east-1 |
| **VPC ID** | aws-transit |
| **Public Subnet** | *mgmt.-us-east-1a |
| **Gateway Size** | t3.small |

* Leave the rest of the default settings  

### Expected Results
After ~2 minutes, your new Aviatrix Transit Gateway should be deployed and visible in Co-Pilot  

Check out CoPilot Topology.  
![Toplogy](images/copilot-transit-gw.png)  
_Fig. Copilot Topology_

## Lab 2.4 - Client / Web Connectivity
### Description
Test Connectivity to Webapp  
### Validate
* Open CoPilot -> **_Topology_**, double-click the **_azure-web-node_cluster_**.  The VNET should open up and you should see the Aviatrix Gateways
* Click the orange Aviatrix Gateway icon, then on the right side, click **_Diag_**
    * This allows you to run pings, traceroutes, test sockets, etc, directly from an AVX Gateway
    * Try to ping:
        * client-int.pod<#>.aviatrixlab.com
        * app.pod<#>.aviatrixlab.com
        * db.pod<#>.aviatrixlab.com

![Toplogy](images/topology-diag.png)  
_Fig. Topology Diag_  
### Expected Results
We have not built any connectivity yet, so none of the connectivity tests should work yet.  

## Lab 2.5 - Attaching Spokes
### Description
Attach Spoke VPCs/VNETs to their Transits
### Validate
* Open the Controller 
* Navigate to **_Multi-Cloud Transit -> Setup -> Attach -> Attach Spoke Gateway_**
* _To speed things up, feel free to open multiple browser tabs, and run a Spoke Attachment step in each tab_
* We need to do this for each of the Spokes:
    * Select _azure-web-node_ and connect it to the _azure-transit_
    * Select _azure-app-node_ and connect it to the _azure-transit_
    * Select _aws-db-node_ and connect it to the _aws-transit-gw_

### Expected Results
Each attachment should take between 30-120 seconds.  Check Co-Pilot Topology to see how the network looks after adding Gateways.  

![Toplogy](images/topology-spokes-attached.png)  
_Fig. Topology Spokes Attached_  

## Lab 2.6 - Test the Web App
### Description
Test the Web App
### Validate
* Open the RDP Client
* Open Firefox from the Desktop on the RDP Client
* Navigate to _http://web.pod<x>.aviatrixlab.com_ or _http://web_

### Expected Results
You should see something similar to this:  
![Webapp](images/webapp-not-working.png)  
_Fig. Webapp_

## Lab 2.7 - Co-Pilot Diagnostics
### Description
Using Co-Pilot Topology to Test Connectivity
### Validate
* Open **_Co-Pilot -> Topology_**, double-click the **_azure-web-node_cluster_** (the blue nodes represent VPCs and VNETs)
* Click on the Aviatrix Gateway icon and select **Diag** on the right side of the screen
* Try to ping:
    * client-int.pod<#>.aviatrixlab.com
    * app.pod<#>.aviatrixlab.com
    * db.pod<#>.aviatrixlab.com
* Try to traceroute:
    * client-int.pod<#>.aviatrixlab.com
    * app.pod<#>.aviatrixlab.com
    * db.pod<#>.aviatrixlab.com
* Check out the Active Sessions or try a Packet Capture

**_Huge benefit to owning the data-path in the cloud!  You have complete visibility and have the tools needed to troubleshoot and operate your network!_**  

### Expected Results
You should see something similar to this:
  
![CoPilot](images/copilot-ping.png)  
_Fig. CoPilot Ping_

Note:
* Since there is no connectivity to AWS, the DB node should not be pingable
* Find network issues quicker with Topology!

## Lab 2.8 - FlowIQ
### Description
Using Co-Pilot FlowIQ to Debug Flows
### Validate
* Open Co-Pilot -> **_FlowIQ_** -> select the **_Records_** tab
* Under **_Edit Filters_**, click **_Add Rule_**, select **_Destination Port_** is equal to **8080** (traffic from Web to App)
* Click **_Add Rule_** again, make sure to select **_OR_**, select **_Destination Port_** is equal to **443** (traffic from App to DB)
* In the date range, select **Last Hour**, click the **Apply** blue button
* In the Records tab, you can view the raw flow logs.  Click **Edit Columns** and add the column **TCP Flag Tags** and **Destination Port** – here you should be able to see the App trying to connect to the DB tier, but we only get a **SYN**

### Expected Results
You should see something similar to this showing successful flows from Web to App, but unsuccessful from App to DB:  

![FlowIQ](images/flowiq.png)  
_Fig. FlowIQ_  

Note:
* No connectivity to the DB tier means that we only see SYNs
* Use FlowIQ to get insights into all flows running over your Cloud Network

## Lab 2.9 - Co-Pilot Topology
### Description
Using Co-Pilot Topology to Visualize your MCNA
### Validate
-	Log in to Co-Pilot
-	Select **_Topology_**

### Expected Results
You should see something similar to this:
  
![Toplogy](images/topology-spokes-attached.png)  
_Fig. Topology_

Note:
* Azure spokes are connected to the Azure Transit
* AWS spoke is connected to the AWS Transit
* We do not have connectivity between AWS and Azure!

**_Visualizing a network can be so helpful!_**

## Lab 2.10 - Multi-Cloud Peering
### Description
By this point we should have verified that connectivity in Azure is good, but we are missing the connectivity between Azure and AWS.  Aviatrix offers an easy, simple but powerful method for interconnecting clouds.

### Validate
* Log in to the Aviatrix Controller
* Navigate to **_Multi-Cloud Transit -> Transit Peering_**
    * Select **_Add New_**
    * Transit Gateway 1:  **aws-transit-gw**
    * Transit Gateway 2:  **azure-transit**
    * Select **OK**

### Expected Results
You should see something similar to this:  
![Transit Peering](images/transit-peering.png)  
_Fig. Transit Peering_  

Note:
-	Check Co-Pilot Topology to verify the links – you may need to refresh or wait ~30s for the Links to become green
-	Congrats!  You have now built a Multi Cloud Network!  Multi-Cloud has never been so easy ..

![CoPilot](images/copilot-transit-peering.png)  
_Fig. CoPilot Transit Peering_  

## Lab 2.11 - Test the Web App
### Description
Check whether the Web App is up and running.

### Validate
* Using the RDP session, open Firefox and navigate to:  _http://web.pod<#>.aviatrixlab.com_
* If the site is already open, click the Refresh button

### Expected Results
You should see something similar to this, meaning the Database is still not up working!
![Webapp](images/webapp-db-down.png)  
_Fig. Webapp_  

## Lab 2.12 - Debug the Egress Rules
### Description
The database is actually just a proxy to AWS DynamoDB.  Perhaps the proxy cannot reach DynamoDB.

### Validate
* After testing the Web App and seeing that the DB connection fails, login to the Co-Pilot
* Navigate to **_Security_**, and click the **_Egress_** tab
* In Egress Search, enter:  *
* Click **Search**

### Expected Results
* It appears that the Egress filter is not allowing access to:  **_dynamodb.eu-central-1.amazonaws.com_**
* You should see somethiing like the following:

![Egress Search](images/egress-search.png)  
_Fig. Egress Search_  
 
## Lab 2.13 - Modify the Egress Rules
### Description
Modify the Egress Rules.
### Validate
* Open the Controller, navigate to **_Security_**, and click **_Egress Control_**
* Scroll down to **_Step #3 – Egress FQDN Filter_**
* Click the **Edit** button next to **_Default-Egress-Policy_**
* Click **Add New** and enter:
    * Domain Name:  **dynamodb.eu-central-1.amazonaws.com**
    * Protocol:  **https**
    * Port:  **443**
    * Action:  **Allow**
* Click **Save**, then click the **_Update_** button  

![Egress Policy](images/egress-policy.png)  
_Fig. Egress Policy_  

### Expected Results
You should have seen whitelist entries for ubuntu.com and github.com, and after adding the whitelist for dynamodb, your WebApp should be working.  

## Lab 2.14 - Sign-in to the WebApp
### Description
Now that we have built the connectivity, our Web App should be up and running.

### Validate
* Log in to the Remote Access Server and open the RDP
* Open Firefox on the Desktop and navigate to: http://web or http://web.pod<#>.aviatrixlab.com
* Click **Sign In**, enter something in the **Comments** and click **Submit** to sign in to the **WALL OF FAME**

### Expected Results
You should see that all 3 App Tiers are now up and can talk to each other.  You should also be able to register yourself in the form, and also be able to view the Wall of Fame!

Nice work! 

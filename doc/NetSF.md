[TOC]

# 将本地应用容器化后发布到SF

####  容器化应用程序

1. 右键单击“Test.Web”项目，再单击“添加” > “容器业务流程协调程序支持” 。 选择“Service Fabric”作为容器业务流程协调程序，然后单击“确定” 。

2. 如果收到提示，单击“是”立即将 Docker 切换到 Windows 容器。

   解决方案中将创建一个新的 Service Fabric 应用程序项目，即“Test.CallCenterApplication”。 系统会向现有的“Test.Web”项目添加一个 Dockerfile。 还会向“Test.Web”项目添加一个“PackageRoot”目录，其中包含新  Test.Web 服务的服务清单和设置 。

   现在可以在 Service Fabric 应用程序中生成和打包该容器。 在计算机上生成容器映像后，即可将其推送到任何容器注册表并下拉到任何主机上运行。

   ***Dockerfile*** 参数说明

   Ensure the Service Fabric cluster you deploy to supports the container image you are using. See https://aka.ms/containerimagehelp for information on Windows container version compatibility.

   ```
   FROM mcr.microsoft.com/dotnet/framework/aspnet:4.7.2
   ARG source
   WORKDIR /inetpub/wwwroot
   COPY ${source:-obj/Docker/publish} .
   ```

   **FROM 参数后是设置SDK的安装包及版本，后面可接OS系统版本**

   

#### 将容器化后的image推送到ACR（Azure Container Registry）

可使用PowerShell脚本创建Azure Container Registry ， 也可以在Azure页面进行部署Azure Container Registry

```powershell
# Variables
$acrresourcegroupname = "fabrikam-acr-group"
$location = "southcentralus"
$registryname="fabrikamregistry$(Get-Random)"

New-AzResourceGroup -Name $acrresourcegroupname -Location $location

$registry = New-AzContainerRegistry -ResourceGroupName $acrresourcegroupname -Name $registryname -EnableAdminUser -Sku Basic
```

配置完成后需要在ACR主界面开启admin权限  生成用户和密码

![image-20210105150422770](C:\Users\vzhao\AppData\Roaming\Typora\typora-user-images\image-20210105150422770.png)

首先，使用 `az acr show` 命令获取注册表的登录服务器。 将 `<acrName>` 替换为在前面步骤中创建的注册表的名称。

```clike
az acr show --name <acrName> --query "{acrLoginServer:loginServer}" --output table
```

接下来，使用注册表登录服务器的 FQDN 更新 `ENV DOCKER_REGISTRY` 行。 本示例体现了示例注册表名称，uniqueregistryname：

```
ENV DOCKER_REGISTRY uniqueregistryname.azurecr.io
```

登录ACR

```clike
az acr login  fabrikamregistry1863241573.azurecr.io
```



## 生成容器映像

使用注册表登录服务器的 FQDN 更新 Dockerfile 之后，可以使用 `docker build` 来创建容器映像。 运行以下命令生成映像，并使用标记将它包含在专用注册表的 URL 中；同样，请将 `<acrName>` 替换为自己的注册表的名称：

Bash复制

```bash
docker build . -f ./AcrHelloworld/Dockerfile -t <acrName>.azurecr.io/acr-helloworld:v1
```

生成 Docker 映像时，会显示多个输出行（此处的显示内容已截断）：

Bash复制

```bash
Sending build context to Docker daemon  523.8kB
Step 1/18 : FROM mcr.microsoft.com/dotnet/core/aspnet:2.2 AS base
2.2: Pulling from mcr.microsoft.com/dotnet/core/aspnet
3e17c6eae66c: Pulling fs layer

[...]

Step 18/18 : ENTRYPOINT dotnet AcrHelloworld.dll
 ---> Running in 6906d98c47a1
 ---> c9ca1763cfb1
Removing intermediate container 6906d98c47a1
Successfully built c9ca1763cfb1
Successfully tagged uniqueregistryname.azurecr.io/acr-helloworld:v1
```

使用 `docker images` 查看生成和标记的映像：

控制台复制

```console
$ docker images
REPOSITORY                                      TAG    IMAGE ID        CREATED               SIZE
uniqueregistryname.azurecr.io/acr-helloworld    v1     01ac48d5c8cf    About a minute ago    284MB
[...]
```

## 向 Azure 容器注册表推送映像



然后，使用 `docker push` 命令将 *acr-helloworld* 映像推送到注册表。 将 `<acrName>` 替换为注册表的名称。

Bash复制

```bash
docker push <acrName>.azurecr.io/acr-helloworld:v1
```

由于已经为异地复制配置了注册表，因此，使用这一条 `docker push` 命令，即可将映像自动复制到“美国西部”和“美国东部”区域。

控制台复制

```console
$ docker push uniqueregistryname.azurecr.io/acr-helloworld:v1
The push refers to a repository [uniqueregistryname.azurecr.io/acr-helloworld]
cd54739c444b: Pushed
d6803756744a: Pushed
b7b1f3a15779: Pushed
a89567dff12d: Pushed
59c7b561ff56: Pushed
9a2f9413d9e4: Pushed
a75caa09eb1f: Pushed
v1: digest: sha256:0799014f91384bda5b87591170b1242bcd719f07a03d1f9a1ddbae72b3543970 size: 1792
```



## 创建群集

应用程序就绪以后，即可创建 Service Fabric 群集，然后将应用程序部署到群集。 [Service Fabric 群集](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-deploy-anywhere)是一组通过网络连接在一起的虚拟机或物理计算机，微服务会在其中部署和管理。

在本教程中，请在 Visual Studio IDE 中创建一个新的三节点型测试群集，然后将应用程序发布到该群集。 请参阅[有关创建和管理群集的教程](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-tutorial-create-vnet-and-windows-cluster)，了解如何创建生产群集。 也可通过 [Azure 门户](https://portal.azure.com/)、[PowerShel](https://docs.microsoft.com/zh-cn/azure/service-fabric/scripts/service-fabric-powershell-create-secure-cluster-cert)、[Azure CLI](https://docs.microsoft.com/zh-cn/azure/service-fabric/scripts/cli-create-cluster) 脚本或 [Azure 资源管理器模板](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-tutorial-create-vnet-and-windows-cluster)将应用程序部署到此前已创建的现有群集。

 备注

应用程序 应用程序和许多其他的应用程序使用 Service Fabric 反向代理在服务之间通信。 通过 Visual Studio 创建的群集默认启用反向代理。 如果部署到现有的群集，则必须[在群集中启用反向代理](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-reverseproxy-setup)，否则 应用程序无法正常运行。

### 找到Web 服务终结点

如果已按照[此教程系列的第一部分](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-tutorial-create-dotnet-app)中的步骤操作，则 应用程序的前端 Web 服务会在特定端口 (8080) 上进行侦听。 当应用程序部署到 Azure 中的群集时，该群集和应用程序都在 Azure 负载均衡器之后运行。 必须使用规则在 Azure 负载均衡器中打开应用程序端口。 此规则通过负载均衡器将入站流量发送到 Web 服务。 端口可以在 **应用程序Web/PackageRoot/ServiceManifest.xml** 文件的 **Endpoint** 元素中找到。

XML复制

```xml
<Endpoint Protocol="http" Name="ServiceEndpoint" Type="Input" Port="8080" />
```

记下服务终结点，后续步骤中需要使用它。 如果要部署到现有群集，请使用 [PowerShell 脚本](https://docs.microsoft.com/zh-cn/azure/service-fabric/scripts/service-fabric-powershell-open-port-in-load-balancer)在 Azure 负载均衡器中创建负载均衡规则和探测，或者在 [Azure 门户](https://portal.azure.com/)中通过此群集的负载均衡器打开此端口。

### 在 Azure 中创建测试群集

以下示例脚本创建一个由五个节点组成的 Service Fabric 群集（使用 X.509 证书保护的群集）。 该命令将创建一个自签名证书，并将其上传到新的 Key Vault。 该证书也会复制到本地目录。 可在[创建 Service Fabric 群集](https://docs.microsoft.com/zh-cn/azure/service-fabric/scripts/service-fabric-powershell-create-secure-cluster-cert)中详细了解如何使用此脚本创建群集。

必要时，请使用 [Azure PowerShell 指南](https://docs.microsoft.com/zh-cn/powershell/azure/)中的说明安装 Azure PowerShell。

在运行以下脚本之前，请在 PowerShell 中运行 `Connect-AzAccount` 来与 Azure 建立连接。

将以下脚本复制到剪贴板，并打开 **Windows PowerShell ISE**。 将内容粘贴到空的 Untitled1.ps1 窗口。 然后，为脚本中的变量提供值：`subscriptionId`、`certpwd`、`certfolder`、`adminuser`、`adminpwd` 等等。 运行该脚本之前，为 `certfolder` 指定的目录必须存在。

PowerShell复制

```powershell
#Provide the subscription Id
$subscriptionId = 'yourSubscriptionId'

# Certificate variables.
$certpwd="Password#1234" | ConvertTo-SecureString -AsPlainText -Force
$certfolder="c:\mycertificates\"

# Variables for VM admin.
$adminuser="vmadmin"
$adminpwd="Password#1234" | ConvertTo-SecureString -AsPlainText -Force 

# Variables for common values
$clusterloc="SouthCentralUS"
$clustername = "mysfcluster"
$groupname="mysfclustergroup"       
$vmsku = "Standard_D2_v2"
$vaultname = "mykeyvault"
$subname="$clustername.$clusterloc.cloudapp.azure.com"

# Set the number of cluster nodes. Possible values: 1, 3-99
$clustersize=5 

# Set the context to the subscription Id where the cluster will be created
Select-AzSubscription -SubscriptionId $subscriptionId

# Create the Service Fabric cluster.
New-AzServiceFabricCluster -Name $clustername -ResourceGroupName $groupname -Location $clusterloc `
-ClusterSize $clustersize -VmUserName $adminuser -VmPassword $adminpwd -CertificateSubjectName $subname `
-CertificatePassword $certpwd -CertificateOutputFolder $certfolder `
-OS WindowsServer2016DatacenterwithContainers -VmSku $vmsku -KeyVaultName $vaultname
```

为变量提供值后，按 **F5** 运行该脚本。

运行脚本并创建群集后，在输出中查找 `ClusterEndpoint`。 例如：

PowerShell复制

```powershell
...
ClusterEndpoint : https://southcentralus.servicefabric.azure.com/runtime/clusters/b76e757d-0b97-4037-a184-9046a7c818c0
```

### 安装群集的证书

现在，我们将在 *CurrentUser\My* 证书存储中安装 PFX。 PFX 文件位于在上述 PowerShell 脚本中使用 `certfolder` 环境变量指定的目录中。

请切换到该目录并运行以下 PowerShell 命令（请替换为 `certfolder` 目录中 PFX 文件的名称，以及在 `certpwd` 变量中指定的密码）。 在此示例中，当前目录设置为 PowerShell 脚本中 `certfolder` 变量指定的目录。 从该位置运行 `Import-PfxCertificate` 命令：

PowerShell复制

```powershell
PS C:\mycertificates> Import-PfxCertificate -FilePath .\mysfclustergroup20190130193456.pfx -CertStoreLocation Cert:\CurrentUser\My -Password (ConvertTo-SecureString Password#1234 -AsPlainText -Force)
```

该命令返回指纹：

PowerShell复制

```powershell
  ...
  PSParentPath: Microsoft.PowerShell.Security\Certificate::CurrentUser\My

Thumbprint                                Subject
----------                                -------
0AC30A2FA770BEF566226CFCF75A6515D73FC686  CN=mysfcluster.SouthCentralUS.cloudapp.azure.com
```

请记下指纹，以便在后续步骤中使用。



***使用VS直接进行创建集群并发布***

在“解决方案资源管理器”中，右键单击“应用程序”并选择“发布” 。

在“连接终结点”中，选择“创建新群集” 。 如果要部署到现有群集，请从列表中选择群集终结点。 此时会打开“创建 Service Fabric 群集”对话框。

在“群集”选项卡中， 输入**群集名称**（例如“mytestcluster”），选择订阅，选择群集的区域（例如“美国中南部”），输入群集节点的数目（对于测试群集，建议使用三节点），然后输入资源组（例如“mytestclustergroup”）。 单击“下一步”。

![屏幕截图显示了“创建 Service Fabric 群集”对话框的“群集”选项卡。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-app-to-party-cluster/create-cluster.png)

在“证书”选项卡中，输入群集证书的密码和输出路径。 自签名证书创建为 PFX 文件并保存到指定的输出路径。 使用证书是为了确保节点到节点和客户端到节点的安全。 请勿将自签名证书用于生产群集。 此证书由 Visual Studio 用于对群集进行身份验证，以及用于部署应用程序。 选择“导入证书”，以便 将 PFX 安装在计算机的 CurrentUser\My certificate 存储中。 单击“下一步”。

![屏幕截图显示了“创建 Service Fabric 群集”对话框的“证书”选项卡。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-app-to-party-cluster/certificate.png)

在“VM 详细信息”选项卡中，输入群集管理员帐户的“用户名”和“密码”。 选择群集节点的“虚拟机映像”，以及每个群集节点的“虚拟机大小”。 单击“高级” 选项卡。

![屏幕截图显示了“创建 Service Fabric 群集”对话框的“VM 详细信息”选项卡。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-app-to-party-cluster/vm-detail.png)

在“端口”中， 输入上一步的Web 服务终结点（例如 8080）。 创建群集以后，这些应用程序端口会在 Azure 负载均衡器中打开，这样就可以将流量转发到群集。 单击“创建”即可创建群集，这需要几分钟的时间。

![屏幕截图显示了“创建 Service Fabric 群集”对话框的“高级”选项卡。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-app-to-party-cluster/advanced.png)

## 将应用程序发布到群集

新群集就绪以后，即可直接通过 Visual Studio 部署 应用程序。

在“解决方案资源管理器”中，右键单击“应用程序”并选择“发布” 。 此时会显示“发布”对话框。

在“连接终结点”中，选择在上一步创建的群集的终结点 。 例如，“mytestcluster.southcentral.cloudapp.azure.com:19000”。 如果选择“高级连接参数”，则会自动填充证书信息。
![发布 Service Fabric 应用程序](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-app-to-party-cluster/publish-app.png)

选择“发布” 。

应用程序部署完以后，请打开浏览器并输入群集地址，后跟 **:8080**。 或者输入另一端口（如果已配置一个）。 示例为 `http://mytestcluster.southcentral.cloudapp.azure.com:8080`。 会看到应用程序在 Azure 群集中运行。 在投票网页中，尝试添加和删除投票选项，并针对这些选项中的一个或多个进行投票





















# 创建 资源管理器模板 使用json文件创建集群

[GitHub 上的 Azure 示例](https://github.com/Azure-Samples/service-fabric-cluster-templates)中提供了示例资源管理器模板。 这些模板可用作群集模板的起点。

本文使用了[五节点安全群集](https://github.com/Azure-Samples/service-fabric-cluster-templates/tree/master/5-VM-Windows-1-NodeTypes-Secure)示例模板和模板参数。 将 *azuredeploy.json* 和 *azuredeploy.parameters.json* 下载到计算机并在你喜欢使用的文本编辑器中打开这两个文件。

 备注

对于国家/地区云（Azure 政府、Azure 中国、Azure 德国），还应将以下 `fabricSettings` 添加到模板：`AADLoginEndpoint`、`AADTokenEndpointFormat` 和 `AADCertEndpointFormat`。

## 添加证书

通过引用包含证书密钥的密钥保管库将证书添加到群集 Resource Manager 模板。 在资源管理器模板参数文件 (*azuredeploy.parameters.json*) 中添加这些密钥保管库参数和值。

## 测试模板

运行以下 PowerShell 命令，使用参数文件测试资源管理器模板：

PowerShell复制

```powershell
Test-AzResourceGroupDeployment -ResourceGroupName "myresourcegroup" -TemplateFile .\azuredeploy.json -TemplateParameterFile .\azuredeploy.parameters.json
```

如果遇到问题并收到含义模糊的消息，请使用“-Debug”作为选项。

PowerShell复制

```powershell
Test-AzResourceGroupDeployment -ResourceGroupName "myresourcegroup" -TemplateFile .\azuredeploy.json -TemplateParameterFile .\azuredeploy.parameters.json -Debug
```

下图演示密钥保管库和 Azure AD 配置在 Resource Manager 模板中的作用。

![Resource Manager 依赖关系图](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-cluster-creation-create-template/cluster-security-arm-dependency-map.png)





# 使用 Azure 容器注册表任务生成和运行容器映像

在本快速入门中，你将使用 [Azure 容器注册表任务](https://docs.microsoft.com/zh-cn/azure/container-registry/container-registry-tasks-overview)命令在 Azure 中以本机方式快速生成、推送和运行 Docker 容器映像，而无需本地安装 Docker。 ACR 任务是 Azure 容器注册表中的一套功能，可在整个容器生命周期内帮助管理和修改容器映像。 此示例说明如何使用本地 Dockerfile 通过按需生成将“内部循环”容器映像开发周期转移到云中。

完成本快速入门后，请使用[教程](https://docs.microsoft.com/zh-cn/azure/container-registry/container-registry-tutorial-quick-task)探索 ACR 任务的更多高级功能。 ACR 任务可以基于代码提交或基础映像更新自动生成映像，或者同时测试多个容器，此外还支持其他一些方案。

如果还没有 [Azure 订阅](https://docs.microsoft.com/zh-cn/azure/guides/developer/azure-developer-guide#understanding-accounts-subscriptions-and-billing)，可以在开始前创建一个[免费帐户](https://azure.microsoft.com/free/?ref=microsoft.com&utm_source=microsoft.com&utm_medium=docs&utm_campaign=visualstudio)。

## 先决条件

- 在 bash 环境中使用 [Azure Cloud Shell](https://docs.microsoft.com/zh-cn/azure/cloud-shell/quickstart)。

  [![嵌入式启动](https://shell.azure.com/images/launchcloudshell.png)](https://shell.azure.com/)

- 如果需要，请[安装](https://docs.microsoft.com/zh-cn/cli/azure/install-azure-cli) Azure CLI 来运行 CLI 参考命令。

  - 如果使用的是本地安装，请通过 Azure CLI 使用 [az login](https://docs.microsoft.com/zh-cn/cli/azure/reference-index#az-login) 命令登录。 若要完成身份验证过程，请遵循终端中显示的步骤。 有关其他登录选项，请参阅[使用 Azure CLI 登录](https://docs.microsoft.com/zh-cn/cli/azure/authenticate-azure-cli)。
  - 出现提示时，请在首次使用时安装 Azure CLI 扩展。 有关扩展详细信息，请参阅[使用 Azure CLI 的扩展](https://docs.microsoft.com/zh-cn/cli/azure/azure-cli-extensions-overview)。
  - 运行 [az version](https://docs.microsoft.com/zh-cn/cli/azure/reference-index?#az_version) 以查找安装的版本和依赖库。 若要升级到最新版本，请运行 [az upgrade](https://docs.microsoft.com/zh-cn/cli/azure/reference-index?#az_upgrade)。

- 本快速入门需要 Azure CLI 2.0.58 或更高版本。 如果使用 Azure Cloud Shell，则最新版本已安装。

## 创建资源组

如果还没有容器注册表，请先使用 [az group create](https://docs.microsoft.com/zh-cn/cli/azure/group#az-group-create) 命令创建一个资源组。 Azure 资源组是在其中部署和管理 Azure 资源的逻辑容器。

以下示例在“eastus”位置创建名为“myResourceGroup”的资源组。

Azure CLI复制试用

```azurecli
az group create --name myResourceGroup --location eastus
```

## 创建容器注册表

使用 [az acr create](https://docs.microsoft.com/zh-cn/cli/azure/acr#az-acr-create) 命令创建容器注册表。 注册表名称在 Azure 中必须唯一，并且包含 5-50 个字母数字字符。 以下示例使用 *myContainerRegistry008*。 将其更新为唯一值。

Azure CLI复制试用

```azurecli
az acr create --resource-group myResourceGroup \
  --name myContainerRegistry008 --sku Basic
```

此示例创建一个基本注册表，这是为了解 Azure 容器注册表的开发人员提供的成本优化选项。 有关可用服务层级的详细信息，请参阅[容器注册表服务层级](https://docs.microsoft.com/zh-cn/azure/container-registry/container-registry-skus)。

## 从 Dockerfile 生成和推送映像

现在，请使用 Azure 容器注册表来生成和推送映像。 首先创建一个本地工作目录，然后创建一个名为“Dockerfile”的 Dockerfile，其中只有一行内容：`FROM mcr.microsoft.com/hello-world`。 这是一个从 Microsoft 容器注册表中托管的 `hello-world` 映像生成 Linux 容器映像的简单示例。 你可以创建自己的标准 Dockerfile 并为其他平台生成映像。 如果使用 bash shell，请使用以下命令创建 Dockerfile：

Bash复制

```bash
echo FROM mcr.microsoft.com/hello-world > Dockerfile
```

运行 [az acr build](https://docs.microsoft.com/zh-cn/cli/azure/acr#az-acr-build) 命令，该命令将生成映像，并在成功生成映像后将其推送到注册表。 以下示例会生成并推送 `sample/hello-world:v1` 映像。 命令末尾处的 `.` 设置 Dockerfile 的位置（在本例中为当前目录）。

Azure CLI复制试用

```azurecli
az acr build --image sample/hello-world:v1 \
  --registry myContainerRegistry008 \
  --file Dockerfile . 
```

成功生成并推送后，输出将如下所示：

控制台复制

```console
Packing source code into tar to upload...
Uploading archived source code from '/tmp/build_archive_b0bc1e5d361b44f0833xxxx41b78c24e.tar.gz'...
Sending context (1.856 KiB) to registry: mycontainerregistry008...
Queued a build with ID: ca8
Waiting for agent...
2019/03/18 21:56:57 Using acb_vol_4c7ffa31-c862-4be3-xxxx-ab8e615c55c4 as the home volume
2019/03/18 21:56:57 Setting up Docker configuration...
2019/03/18 21:56:58 Successfully set up Docker configuration
2019/03/18 21:56:58 Logging in to registry: mycontainerregistry008.azurecr.io
2019/03/18 21:56:59 Successfully logged into mycontainerregistry008.azurecr.io
2019/03/18 21:56:59 Executing step ID: build. Working directory: '', Network: ''
2019/03/18 21:56:59 Obtaining source code and scanning for dependencies...
2019/03/18 21:57:00 Successfully obtained source code and scanned for dependencies
2019/03/18 21:57:00 Launching container with name: build
Sending build context to Docker daemon  13.82kB
Step 1/1 : FROM mcr.microsoft.com/hello-world
latest: Pulling from hello-world
Digest: sha256:2557e3c07ed1e38f26e389462d03ed943586fxxxx21577a99efb77324b0fe535
Successfully built fce289e99eb9
Successfully tagged mycontainerregistry008.azurecr.io/sample/hello-world:v1
2019/03/18 21:57:01 Successfully executed container: build
2019/03/18 21:57:01 Executing step ID: push. Working directory: '', Network: ''
2019/03/18 21:57:01 Pushing image: mycontainerregistry008.azurecr.io/sample/hello-world:v1, attempt 1
The push refers to repository [mycontainerregistry008.azurecr.io/sample/hello-world]
af0b15c8625b: Preparing
af0b15c8625b: Layer already exists
v1: digest: sha256:92c7f9c92844bbbb5d0a101b22f7c2a7949e40f8ea90c8b3bc396879d95e899a size: 524
2019/03/18 21:57:03 Successfully pushed image: mycontainerregistry008.azurecr.io/sample/hello-world:v1
2019/03/18 21:57:03 Step ID: build marked as successful (elapsed time in seconds: 2.543040)
2019/03/18 21:57:03 Populating digests for step ID: build...
2019/03/18 21:57:05 Successfully populated digests for step ID: build
2019/03/18 21:57:05 Step ID: push marked as successful (elapsed time in seconds: 1.473581)
2019/03/18 21:57:05 The following dependencies were found:
2019/03/18 21:57:05
- image:
    registry: mycontainerregistry008.azurecr.io
    repository: sample/hello-world
    tag: v1
    digest: sha256:92c7f9c92844bbbb5d0a101b22f7c2a7949e40f8ea90c8b3bc396879d95e899a
  runtime-dependency:
    registry: registry.hub.docker.com
    repository: library/hello-world
    tag: v1
    digest: sha256:2557e3c07ed1e38f26e389462d03ed943586f744621577a99efb77324b0fe535
  git: {}

Run ID: ca8 was successful after 10s
```

## 运行映像

现在，请快速运行已生成并推送到注册表的映像。 此处使用 [az acr run](https://docs.microsoft.com/zh-cn/cli/azure/acr#az-acr-run) 运行容器命令。 在容器开发工作流中，这可能是部署映像之前的验证步骤，或者你可以将该命令包含在[多步骤 YAML 文件](https://docs.microsoft.com/zh-cn/azure/container-registry/container-registry-tasks-multi-step)中。

以下示例使用 `$Registry` 指定运行命令的注册表：

Azure CLI复制试用

```azurecli
az acr run --registry myContainerRegistry008 \
  --cmd '$Registry/sample/hello-world:v1' /dev/null
```

此示例中的 `cmd` 参数以其默认配置运行容器，但 `cmd` 支持附加 `docker run` 参数甚至其他 `docker` 命令。

输出与下面类似：

控制台复制

```console
Packing source code into tar to upload...
Uploading archived source code from '/tmp/run_archive_ebf74da7fcb04683867b129e2ccad5e1.tar.gz'...
Sending context (1.855 KiB) to registry: mycontainerre...
Queued a run with ID: cab
Waiting for an agent...
2019/03/19 19:01:53 Using acb_vol_60e9a538-b466-475f-9565-80c5b93eaa15 as the home volume
2019/03/19 19:01:53 Creating Docker network: acb_default_network, driver: 'bridge'
2019/03/19 19:01:53 Successfully set up Docker network: acb_default_network
2019/03/19 19:01:53 Setting up Docker configuration...
2019/03/19 19:01:54 Successfully set up Docker configuration
2019/03/19 19:01:54 Logging in to registry: mycontainerregistry008.azurecr.io
2019/03/19 19:01:55 Successfully logged into mycontainerregistry008.azurecr.io
2019/03/19 19:01:55 Executing step ID: acb_step_0. Working directory: '', Network: 'acb_default_network'
2019/03/19 19:01:55 Launching container with name: acb_step_0

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/

2019/03/19 19:01:56 Successfully executed container: acb_step_0
2019/03/19 19:01:56 Step ID: acb_step_0 marked as successful (elapsed time in seconds: 0.843801)

Run ID: cab was successful after 6s
```

## 清理资源

如果不再需要存储在该处的资源组、容器注册表和容器映像，可以使用 [az group delete](https://docs.microsoft.com/zh-cn/cli/azure/group#az-group-delete) 命令将其删除。

Azure CLI复制

```azurecli
az group delete --name myResourceGroup
```





# 使用 Docker CLI 将第一个映像推送到专用 Docker 容器注册表

Azure 容器注册表存储和管理专用 [Docker](https://hub.docker.com/) 容器映像，其方式类似于 [Docker Hub](https://hub.docker.com/) 存储公共 Docker 映像。 可以使用 [Docker 命令行接口](https://docs.docker.com/engine/reference/commandline/cli/) (Docker CLI) 对容器注册表执行[登录](https://docs.docker.com/engine/reference/commandline/login/)、[推送](https://docs.docker.com/engine/reference/commandline/push/)、[提取](https://docs.docker.com/engine/reference/commandline/pull/)和其他操作。

以下步骤从公共 Docker 中心注册表下载正式的 [Nginx 映像](https://store.docker.com/images/nginx)，为专用 Azure 容器注册表标记该映像，将其推入到注册表，然后从注册表提取。

## 必备条件

- **Azure 容器注册表** - 在 Azure 订阅中创建容器注册表。 例如，使用 [Azure 门户](https://docs.microsoft.com/zh-cn/azure/container-registry/container-registry-get-started-portal)或 [Azure CLI](https://docs.microsoft.com/zh-cn/azure/container-registry/container-registry-get-started-azure-cli)。
- **Docker CLI** - 还必须在本地安装 Docker。 Docker 提供的包可在任何 [macOS](https://docs.docker.com/docker-for-mac/)、[Windows](https://docs.docker.com/docker-for-windows/) 或 [Linux](https://docs.docker.com/engine/installation/#supported-platforms) 系统上轻松配置 Docker。

## 登录到注册表

可[通过多种方式验证](https://docs.microsoft.com/zh-cn/azure/container-registry/container-registry-authentication)专用容器注册表。 在命令行中操作时，建议的方法是使用 Azure CLI 命令 [az acr login](https://docs.microsoft.com/zh-cn/cli/azure/acr?view=azure-cli-latest#az-acr-login)。 例如，若要登录到名为 *myregistry* 的注册表：

Azure CLI复制

```azurecli
az acr login --name myregistry
```

也可以使用 [docker login](https://docs.docker.com/engine/reference/commandline/login/) 登录。 例如，你可能在自动化方案中向注册表[分配了服务主体](https://docs.microsoft.com/zh-cn/azure/container-registry/container-registry-authentication#service-principal)。 运行以下命令时，收到提示后，请以交互方式提供服务主体 appID（用户名）和密码。 有关管理登录凭据的最佳做法，请参阅 [docker login](https://docs.docker.com/engine/reference/commandline/login/) 命令参考：

复制

```
docker login myregistry.azurecr.io
```

完成后，这两个命令将返回 `Login Succeeded`。

 提示

使用 `docker login` 以及标记要推送到注册表的映像时，请始终指定完全限定的注册表名称（全部小写）。 在本文的示例中，完全限定的名称为 *myregistry.azurecr.io*。

## 提取正式的 Nginx 映像

首次将公共 Nginx 映像提取到本地计算机。

复制

```
docker pull nginx
```

## 在本地运行容器

执行以下 [docker run](https://docs.docker.com/engine/reference/run/) 命令，在端口 8080 上以交互方式启动 Nginx 容器的本地实例 (`-it`)。 `--rm` 参数指定在停止容器时应将其删除。

复制

```
docker run -it --rm -p 8080:80 nginx
```

浏览到 `http://localhost:8080`，查看由正在运行的容器中的 Nginx 提供服务的默认网页。 应看到类似于下面的页面：

![本地计算机上的 Nginx](https://docs.microsoft.com/zh-cn/azure/container-registry/media/container-registry-get-started-docker-cli/nginx.png)

由于已使用 `-it` 以交互方式启动了容器，因此在浏览器中导航到该容器后，可在命令行中查看 Nginx 服务器的输出。

若要停止并删除容器，请按 `Control`+`C`。

## 创建映像的别名

运行 [docker tag](https://docs.docker.com/engine/reference/commandline/tag/)，使用注册表的完全限定路径创建映像的别名。 此示例指定了 `samples` 命名空间，以免注册表根目录中出现混乱。

复制

```
docker tag nginx myregistry.azurecr.io/samples/nginx
```

有关使用命名空间进行标记的详细信息，请参阅 [Azure 容器注册表的最佳做法](https://docs.microsoft.com/zh-cn/azure/container-registry/container-registry-best-practices)的[存储库命名空间](https://docs.microsoft.com/zh-cn/azure/container-registry/container-registry-best-practices#repository-namespaces)部分。

## 将映像推送到注册表

使用专用注册表的完全限定路径标记映像后，可以使用 [docker push](https://docs.docker.com/engine/reference/commandline/push/) 将其推送到注册表：

复制

```
docker push myregistry.azurecr.io/samples/nginx
```

## 从注册表中提取映像

使用 [docker pull](https://docs.docker.com/engine/reference/commandline/pull/) 命令从注册表提取映像：

复制

```
docker pull myregistry.azurecr.io/samples/nginx
```

## 启动 Nginx 容器

使用 [docker run](https://docs.docker.com/engine/reference/run/) 命令运行已从注册表提取的映像：

复制

```
docker run -it --rm -p 8080:80 myregistry.azurecr.io/samples/nginx
```

浏览到 `http://localhost:8080` 以查看正在运行的容器。

若要停止并删除容器，请按 `Control`+`C`。

## 删除映像（可选）

如果不再需要 Nginx 映像，可以使用 [docker rmi](https://docs.docker.com/engine/reference/commandline/rmi/) 命令在本地将其删除。

复制

```
docker rmi myregistry.azurecr.io/samples/nginx
```

若要从 Azure 容器注册表中删除映像，可以使用 Azure CLI 命令[az acr repository delete](https://docs.microsoft.com/zh-cn/cli/azure/acr/repository#az-acr-repository-delete)。 例如，以下命令删除 `samples/nginx:latest` 标记引用的清单、所有唯一的层数据以及引用此清单的其他所有标记。

Azure CLI复制

```azurecli
az acr repository delete --name myregistry --image samples/nginx:latest
```

## 后续步骤

了解基础知识后，便可以开始使用注册表了！ 例如，将容器映像从注册表部署到：

- [Azure Kubernetes 服务 (AKS)](https://docs.microsoft.com/zh-cn/azure/aks/tutorial-kubernetes-prepare-app)
- [Azure 容器实例](https://docs.microsoft.com/zh-cn/azure/container-instances/container-instances-tutorial-prepare-app)
- [Service Fabric](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-tutorial-create-container-images)

可以选择安装[适用于 Visual Studio Code 的 Docker 扩展](https://code.visualstudio.com/docs/azure/docker)以及适用于 Azure 容器注册表的 [Azure 帐户](https://marketplace.visualstudio.com/items?itemName=ms-vscode.azure-account)扩展。 通过 Azure 容器注册表拉取和推送映像，或者运行 ACR 任务，这一切都可以在 Visual Studio Code 中进行。

# 教程：通过 CI/CD 将容器应用程序部署到 Service Fabric 群集

本教程是一个系列的第二部分，介绍了如何使用 Visual Studio 和 Azure DevOps 为 Azure Service Fabric 容器应用程序设置持续集成和部署。 需要一个现有的 Service Fabric 应用程序，将使用[将 Windows 容器中的 .NET 应用程序部署到 Azure Service Fabric](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-host-app-in-a-container) 中创建的应用程序作为示例。

本系列教程的第二部分将介绍如何：

- 向项目中添加源代码管理
- 在 Visual Studio 团队资源管理器中创建生成定义
- 在 Visual Studio 团队资源管理器中创建发布定义
- 自动部署和升级应用程序

## 先决条件

在开始学习本教程之前：

- 在 Azure 上拥有一个群集，或者[使用此教程创建一个群集](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-tutorial-create-vnet-and-windows-cluster)
- [将容器化的应用程序部署到该群集](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-host-app-in-a-container)

## 准备一个发布配置文件

现在，你已[部署了一个容器应用程序](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-host-app-in-a-container)，可以设置持续集成了。 首先，在应用程序中准备一个发布配置文件，供要在 Azure DevOps 中执行的部署进程使用。 应当将发布配置文件配置为以你之前创建的群集为目标。 启动 Visual Studio 并打开一个现有的 Service Fabric 应用程序项目。 在“解决方案资源管理器”中，右键单击该应用程序并选择“发布...”。

在应用程序项目中选择一个要用于持续集成工作流的目标配置文件，例如 Cloud。 指定群集连接终结点。 选中“升级应用程序”复选框，以便应用程序针对 Azure DevOps 中的每个部署进行升级。 单击“保存”超链接将设置保存到发布配置文件，然后单击“取消”关闭对话框。

![推送配置文件](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/publishappprofile.png)

## 将你的 Visual Studio 解决方案共享到一个新的 Azure DevOps Git 存储库

将你的应用程序源文件共享到 Azure DevOps 中的一个团队项目，以便可以生成内部版本。

通过在 Visual Studio 的右下角的状态栏中选择“添加到源代码管理” -> “Git”为项目创建一个新的本地 Git 存储库。

在“团队资源管理器”中的“推送”视图中，在“推送到 Azure DevOps”下选择“发布 Git 存储库”按钮。

![Visual Studio 中“团队资源管理器 - 同步”窗口的屏幕截图。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/publishgitrepo.png)

验证你的电子邮件地址并在“帐户”下拉列表中选择你的组织。 如果还没有组织，可能必须设置一个组织。 输入你的存储库名称并选择“发布存储库”。

![“推送到 Azure DevOps”窗口的屏幕截图。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/publishcode.png)

发布存储库会在你的帐户中创建一个与本地存储库同名的新团队项目。 若要在现有团队项目中创建存储库，请单击“存储库名称”旁边的“高级”并选择一个团队项目。 可以通过选择“在 web 上查看”来在 web 上查看代码。

## 使用 Azure Pipelines 配置持续交付

Azure DevOps 生成定义所描述的工作流由一系列按顺序执行的生成步骤组成。 创建一个生成定义，以生成要部署到 Service Fabric 群集的 Service Fabric 应用程序包和其他项目。 详细了解 Azure DevOps [生成定义](https://www.visualstudio.com/docs/build/define/create)。

Azure DevOps 发布定义描述了将应用程序程序包部署到群集的工作流。 一起使用时，生成定义和发布定义将执行从开始到结束的整个工作流，即一开始只有源文件，而结束时群集中会有一个运行的应用程序。 详细了解 Azure DevOps [发布定义](https://www.visualstudio.com/docs/release/author-release-definition/more-release-definition)。

### 创建生成定义

打开新的团队项目，方法是：在 Web 浏览器中导航到 [https://dev.azure.com](https://dev.azure.com/) ，选择你的组织，后跟新项目。

选择左面板上的“管道”选项，然后单击“新建管道” 。

 备注

如果没有看到生成定义模板，请确保已关闭“新 YAML 管道创建体验” 功能。 此功能在 DevOps 帐户的“预览功能” 部分中配置。

![新建管道](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/newpipeline.png)

选择 **Azure Repos Git** 作为源，然后选择团队项目名称、项目存储库，以及 **master** 默认分库或者手动的和计划的生成。 然后单击“继续” 。

在“选择模板”中，选择“支持 Docker 的 Azure Service Fabric 应用程序”模板，然后单击“应用” 。

![选择“生成模板”](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/selectbuildtemplate.png)

在“任务”中，输入 **Hosted VS2017** 作为 **代理池**。

![选择“任务”](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/taskagentpool.png)

单击“标记图像” 。

在“容器注册表类型”中，选择“Azure 容器注册表”。 选择一个 **Azure 订阅**，然后单击“授权”。 选择一个 **Azure 容器注册表**。

![选择 Docker 标记映像](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/dockertagimages.png)

单击“推送映像”。

在“容器注册表类型”中，选择“Azure 容器注册表”。 选择一个 **Azure 订阅**，然后单击“授权”。 选择一个 **Azure 容器注册表**。

![选择 Docker 推送映像](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/dockerpushimages.png)

在“触发器”选项卡下，选中“启用持续集成”来启用持续集成。 在 **分支筛选器** 中，单击“+ 添加” ，**分支规范** 将默认为“主” 。

在“保存生成管道和队列”对话框 中，单击“保存并排队” 以手动启动生成。

![选择“触发器”](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/saveandqueue.png)

在推送或签入时也会触发生成。 若要检查生成进度，请切换到“生成”选项卡 。在验证生成成功执行后，定义用于将应用程序部署到群集的发布定义。

### 创建发布定义

选择左面板上的“管道”选项，然后选择“发布”和“+ 新建管道” 。 在“选择模板”中，从列表中选择“Azure Service Fabric 部署”模板，然后单击“应用” 。

![选择发布模板](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/selectreleasetemplate.png)

依次选择“任务”、“环境 1”和“+ 新建”来添加新的群集连接。

![添加群集连接](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/addclusterconnection.png)

在“添加新的 Service Fabric 连接”视图中，选择“基于证书的”或“Azure Active Directory”身份验证。 指定连接名称“mysftestcluster”和群集终结点“tcp://mysftestcluster.southcentralus.cloudapp.azure.com:19000”（或你要部署到的群集的终结点）。

对于基于证书的身份验证，添加用来创建群集的服务器证书的 **服务器证书指纹**。 在“客户端证书”中，添加客户端证书文件的 base-64 编码。 有关如何获取证书的 base-64 编码表示形式的信息，请参阅有关该字段的帮助弹出项。 还需要添加证书的 **密码**。 如果没有单独的客户端证书，可以使用群集或服务器证书。

对于 Azure Active Directory 凭据，请添加用来创建群集的服务器证书的 **服务器证书指纹**，并在“用户名” 和“密码” 字段中添加要用来连接到群集的凭据。

单击“添加” 以保存群集连接。

在“代理阶段”下，单击“部署 Service Fabric 应用程序” 。 单击“Docker 设置” ，然后单击“配置 Docker 设置” 。 在“注册表凭据源” 中，选择“Azure 资源管理器服务连接” 。 然后，选择你的 **Azure 订阅**。

![发布管道代理](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/releasepipelineagent.png)

接下来，向管道添加一个生成项目，以便发布定义可以找到生成输出。 依次选择“管道”和“项目”->“+ 添加”。 在“源(生成定义)” 中，选择之前创建的生成定义。 单击“添加”以保存生成项目。

![添加项目](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/addartifact.png)

启用一个持续部署触发器，以便在生成完成时自动创建发布。 单击该项目中的闪电图标，启用该触发器，然后单击“保存” 以保存发布定义。

![启用触发器](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/enabletrigger.png)

选择“+ 发布” -> “创建发布” -> “创建”，手动创建发布 。 可以在“发布” 选项卡中监视发布进度。

验证部署是否已成功且应用程序是否正在群集中运行。 打开 Web 浏览器并导航到 `http://mysftestcluster.southcentralus.cloudapp.azure.com:19080/Explorer/`。 记下应用程序版本，在本例中为“1.0.0.20170616.3”。

## 提交并推送更改，触发发布

通过将一些代码更改签入到 Azure DevOps 来验证持续集成管道是否正常工作。

在编写代码时，Visual Studio 会自动跟踪代码更改。 通过从右下角的状态栏中选择“挂起的更改”图标（![“挂起的更改”图标显示一支铅笔和一个数字。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/pending.png)）来将更改提交到本地 Git 存储库。

在“团队资源管理器”中的“更改”视图中，添加一条消息来说明你的更新，然后提交更改。

![全部提交](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/changes.png)

在“团队资源管理器”中选择“未发布的更改”状态栏图标（![未发布的更改](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/unpublishedchanges.png)）或“同步”视图。 选择“推送”以更新 Azure DevOps 中的代码。

![推送更改](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/push.png)

将更改推送到 Azure DevOps 会自动触发生成。 当生成定义成功完成时，会自动创建一个发布，并将开始升级群集上的应用程序。

若要检查生成进度，请在 Visual Studio 中切换到“团队资源管理器”中的“生成”选项卡。 在验证生成成功执行后，定义用于将应用程序部署到群集的发布定义。

验证部署是否已成功且应用程序是否正在群集中运行。 打开 Web 浏览器并导航到 `http://mysftestcluster.southcentralus.cloudapp.azure.com:19080/Explorer/`。 记下应用程序版本，在本例中为“1.0.0.20170815.3”。

![Service Fabric Explorer 中 Voting 应用的屏幕截图。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/sfx1.png)

## 更新应用程序

在应用程序中进行代码更改。 按照前面的步骤保存并提交更改。

在应用程序升级开始后，可以在 Service Fabric Explorer 中观察升级进度：

![Service Fabric Explorer 中 Voting 应用的屏幕截图。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/sfx2.png)

应用程序升级可能要花费几分钟时间才能完成。 当升级完成后，应用程序将运行下一版本。 在本例中为“1.0.0.20170815.4”。

![Service Fabric Explorer 中 Voting 应用的屏幕截图。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-tutorial-deploy-container-app-with-cicd-vsts/sfx3.png)







# 如何在 Service Fabric 中使用参数来指定服务的端口号

本文演示如何使用 Visual Studio 在 Service Fabric 中通过参数来指定服务的端口号。

## 使用参数来指定服务的端口号的过程

在此示例中，使用参数来设置 ASP.NET Core Web API 的端口号。

1. 打开 Visual Studio 并创建新的 Service Fabric 应用程序。

2. 选择无状态 ASP.NET Core 模板。

3. 选择 Web API。

4. 打开 ServiceManifest.xml 文件。

5. 记下为你的服务指定的终结点的名称。 默认为 `ServiceEndpoint`。

6. 打开 ApplicationManifest.xml 文件

7. 在 `ServiceManifestImport` 元素中，添加新的 `RessourceOverrides` 元素，其中包括对 ServiceManifest.xml 文件中终结点的引用。

   XML复制

   ```xml
     <ServiceManifestImport>
       <ServiceManifestRef ServiceManifestName="Web1Pkg" ServiceManifestVersion="1.0.0" />
       <ResourceOverrides>
         <Endpoints>
           <Endpoint Name="ServiceEndpoint"/>
         </Endpoints>
       </ResourceOverrides>
       <ConfigOverrides />
     </ServiceManifestImport>
   ```

8. 在 `Endpoint` 元素中，现在可使用参数替换任何属性。 本示例中，使用方括号指定 `Port` 并将其设置为参数名称 - 例如，`[MyWebAPI_PortNumber]`

   XML复制

   ```xml
     <ServiceManifestImport>
       <ServiceManifestRef ServiceManifestName="Web1Pkg" ServiceManifestVersion="1.0.0" />
       <ResourceOverrides>
         <Endpoints>
           <Endpoint Name="ServiceEndpoint" Port="[MyWebAPI_PortNumber]"/>
         </Endpoints>
       </ResourceOverrides>
       <ConfigOverrides />
     </ServiceManifestImport>
   ```

9. 仍在 ApplicationManifest.xml 文件中，然后在 `Parameters` 元素中指定参数

   XML复制

   ```xml
     <Parameters>
       <Parameter Name="MyWebAPI_PortNumber" />
     </Parameters>
   ```

10. 并定义 `DefaultValue`

    XML复制

    ```xml
      <Parameters>
        <Parameter Name="MyWebAPI_PortNumber" DefaultValue="8080" />
      </Parameters>
    ```

11. 打开 ApplicationParameters 文件夹和 `Cloud.xml` 文件

12. 若要指定在发布到远程群集时要使用的其他端口，请将带有端口号的参数添加到此文件。

    XML复制

    ```xml
      <Parameters>
        <Parameter Name="MyWebAPI_PortNumber" Value="80" />
      </Parameters>
    ```

使用 Cloud.xml 发布配置文件从 Visual Studio 发布应用程序时，服务将配置为使用端口 80。 如果在未指定 MyWebAPI_PortNumber 参数的情况下部署应用程序，则服务使用端口 8080。



# 如何在 Service Fabric 中参数化配置文件

本文演示如何在 Service Fabric 中参数化配置文件。 如果还不熟悉管理多个环境的应用程序的核心概念，请阅读[管理多个环境的应用程序](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manage-multiple-environment-app-configuration)。

## 参数化配置文件的过程

在此示例中，在应用程序部署中使用参数来替代配置值。

1. 打开服务项目中的 *<MyService>\PackageRoot\Config\Settings.xml* 文件。

2. 通过添加以下 XML，设置配置参数名称和值，例如高速缓存大小等于 25：

   XML复制

   ```xml
    <Section Name="MyConfigSection">
      <Parameter Name="CacheSize" Value="25" />
    </Section>
   ```

3. 保存并关闭该文件。

4. 打开 *<MyApplication>\ApplicationPackageRoot\ApplicationManifest.xml* 文件。

5. 在 ApplicationManifest.xml 文件的 `Parameters` 元素中声明参数和默认值。 建议参数名称包含服务的名称（例如，“MyService”）。

   XML复制

   ```xml
    <Parameters>
      <Parameter Name="MyService_CacheSize" DefaultValue="80" />
    </Parameters>
   ```

6. 在 ApplicationManifest.xml 文件的 `ServiceManifestImport` 节中，添加 `ConfigOverrides` 和 `ConfigOverride` 元素，引用配置包、节和参数。

   XML复制

   ```xml
    <ConfigOverrides>
      <ConfigOverride Name="Config">
          <Settings>
            <Section Name="MyConfigSection">
                <Parameter Name="CacheSize" Value="[MyService_CacheSize]" />
            </Section>
          </Settings>
      </ConfigOverride>
    </ConfigOverrides>
   ```







# 使用用户分配的托管标识部署 Service Fabric 应用程序

若要使用托管标识部署 Service Fabric 应用程序，需通过 Azure 资源管理器部署应用程序，通常需要使用 Azure 资源管理器模板。 若要详细了解如何通过 Azure 资源管理器部署 Service Fabric 应用程序，请参阅[将应用程序和服务作为 Azure 资源管理器资源进行管理](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-arm-resource)。

 备注

未部署为 Azure 资源的应用程序**不能**有托管标识。

API 版本 `"2019-06-01-preview"` 支持使用托管标识部署 Service Fabric 应用程序。 另外，不管应用程序类型、应用程序类型版本和服务资源如何，你都可以使用同一 API 版本。

## 用户分配的标识

若要为应用程序启用用户分配的托管标识，请先将类型为 **userAssigned** 的 **identity** 属性添加到应用程序资源和引用的用户分配标识。 然后将 **managedIdentities** 节添加到 **application** 资源的 **properties** 节中，该资源包含一个易记名称的列表，可以为每个用户分配的标识进行 principalId 映射。 有关用户分配的标识的详细信息，请参阅[创建、列出或删除用户分配的托管标识](https://docs.microsoft.com/zh-cn/azure/active-directory/managed-identities-azure-resources/how-to-manage-ua-identity-powershell)。

### 应用程序模板

若要为应用程序启用用户分配的托管标识，请先将类型为 **userAssigned** 的 **identity** 属性添加到应用程序资源和引用的用户分配标识，然后将 **managedIdentities** 对象添加到 **properties** 节中，该节包含一个易记名称的列表，可以为每个用户分配的标识进行 principalId 映射。

JSON复制

```json
{
  "apiVersion": "2019-06-01-preview",
  "type": "Microsoft.ServiceFabric/clusters/applications",
  "name": "[concat(parameters('clusterName'), '/', parameters('applicationName'))]",
  "location": "[resourceGroup().location]",
  "dependsOn": [
    "[concat('Microsoft.ServiceFabric/clusters/', parameters('clusterName'), '/applicationTypes/', parameters('applicationTypeName'), '/versions/', parameters('applicationTypeVersion'))]",
    "[resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', parameters('userAssignedIdentityName'))]"
  ],
  "identity": {
    "type" : "userAssigned",
    "userAssignedIdentities": {
        "[resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', parameters('userAssignedIdentityName'))]": {}
    }
  },
  "properties": {
    "typeName": "[parameters('applicationTypeName')]",
    "typeVersion": "[parameters('applicationTypeVersion')]",
    "parameters": {
    },
    "managedIdentities": [
      {
        "name" : "[parameters('userAssignedIdentityName')]",
        "principalId" : "[reference(resourceId('Microsoft.ManagedIdentity/userAssignedIdentities/', parameters('userAssignedIdentityName')), '2018-11-30').principalId]"
      }
    ]
  }
}
```

在上面的示例中，用户分配标识的资源名称用作应用程序的托管标识的易记名称。 以下示例假定实际的易记名称为“AdminUser”。

### 应用程序包

1. 对于在 Azure 资源管理器模板的 `managedIdentities` 节中定义的每个标识，请在应用程序清单的 **Principals** 节下添加 `<ManagedIdentity>` 标记。 `Name` 属性需与 `managedIdentities` 节中定义的 `name` 属性匹配。

   **ApplicationManifest.xml**

   XML复制

   ```xml
     <Principals>
       <ManagedIdentities>
         <ManagedIdentity Name="AdminUser" />
       </ManagedIdentities>
     </Principals>
   ```

2. 在 **ServiceManifestImport** 节中，为使用托管标识的服务添加 **IdentityBindingPolicy**。 此策略将 `AdminUser` 标识映射到特定于服务的标识名称，该名称需在以后添加到服务清单中。

   **ApplicationManifest.xml**

   XML复制

   ```xml
     <ServiceManifestImport>
       <Policies>
         <IdentityBindingPolicy ServiceIdentityRef="WebAdmin" ApplicationIdentityRef="AdminUser" />
       </Policies>
     </ServiceManifestImport>
   ```

3. 更新服务清单，将 **ManagedIdentity** 添加到 **Resources** 节中，其名称与应用程序清单的 `IdentityBindingPolicy` 中的 `ServiceIdentityRef` 匹配：

   **ServiceManifest.xml**

   XML复制

   ```xml
     <Resources>
       ...
       <ManagedIdentities DefaultIdentity="WebAdmin">
         <ManagedIdentity Name="WebAdmin" />
       </ManagedIdentities>
     </Resources>
   ```







# 配置应用程序的存储库凭据以下载容器映像

通过将 `RepositoryCredentials` 添加到应用程序清单的 `ContainerHostPolicies` 部分来配置容器注册表身份验证。 在以下示例中，为容器注册表 (*myregistry.azurecr.io* 添加帐户和密码) ，这允许服务从存储库下载容器映像。

XML复制

```xml
<ServiceManifestImport>
    ...
    <Policies>
        <ContainerHostPolicies CodePackageRef="Code">
            <RepositoryCredentials AccountName="myregistry" Password="=P==/==/=8=/=+u4lyOB=+=nWzEeRfF=" PasswordEncrypted="false"/>
            <PortBinding ContainerPort="80" EndpointRef="Guest1TypeEndpoint"/>
        </ContainerHostPolicies>
    </Policies>
    ...
</ServiceManifestImport>
```

建议使用部署到群集所有节点的加密证书，对存储库密码加密。 当 Service Fabric 将服务包部署到群集时，即可使用加密证书解密密码文本。 Invoke-ServiceFabricEncryptText cmdlet 用于为密码创建密码文本，后者将添加到 ApplicationManifest.xml 文件中。 有关证书和加密语义的详细信息，请参阅[机密管理](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-secret-management)。

## 配置群集级凭据

Service Fabric 允许你配置群集级凭据，应用程序可以将这些凭据用作默认存储库凭据。

可以通过在 ApplicationManifest.xml 中向 `ContainerHostPolicies` 添加 `UseDefaultRepositoryCredentials` 属性来启用或禁用此功能；将其值设为 `true` 则启用，将其值设为 `false` 则禁用。

XML复制

```xml
<ServiceManifestImport>
    ...
    <Policies>
        <ContainerHostPolicies CodePackageRef="Code" UseDefaultRepositoryCredentials="true">
            <PortBinding ContainerPort="80" EndpointRef="Guest1TypeEndpoint"/>
        </ContainerHostPolicies>
    </Policies>
    ...
</ServiceManifestImport>
```

然后，Service Fabric 会使用可在 ClusterManifest 中的 `Hosting` 部分下指定的默认存储库凭据。 如果 `UseDefaultRepositoryCredentials` 为 `true`，则 Service Fabric 将从 ClusterManifest 中读取以下值：

- DefaultContainerRepositoryAccountName (string)
- DefaultContainerRepositoryPassword (string)
- IsDefaultContainerRepositoryPasswordEncrypted (bool)
- DefaultContainerRepositoryPasswordType（字符串）

下面是可以在 ClusterManifestTemplate.json 文件中的 `Hosting` 部分内添加的内容的示例。 可以在群集创建时或配置升级后期添加 `Hosting` 节。 有关详细信息，请参阅[更改 Azure Service Fabric 群集设置](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-cluster-fabric-settings)和[管理 Azure Service Fabric 应用程序机密](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-secret-management)

JSON复制

```json
"fabricSettings": [
    ...,
    {
        "name": "Hosting",
        "parameters": [
          {
            "name": "EndpointProviderEnabled",
            "value": "true"
          },
          {
            "name": "DefaultContainerRepositoryAccountName",
            "value": "someusername"
          },
          {
            "name": "DefaultContainerRepositoryPassword",
            "value": "somepassword"
          },
          {
            "name": "IsDefaultContainerRepositoryPasswordEncrypted",
            "value": "false"
          },
          {
            "name": "DefaultContainerRepositoryPasswordType",
            "value": "PlainText"
          }
        ]
      },
]
```

## 使用令牌作为注册表凭据

Service Fabric 支持使用令牌作为凭据下载容器的映像。 此功能利用基础虚拟机规模集的托管标识对注册表进行身份验证，从而消除了管理用户凭据的需要。 请参阅 [Azure 资源的托管标识](https://docs.microsoft.com/zh-cn/azure/active-directory/managed-identities-azure-resources/overview)获取详细信息。 使用此功能需要执行以下步骤：

1. 确保已为 VM 启用系统分配的托管标识。

   ![Azure 门户：创建虚拟机规模集标识选项](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/configure-container-repository-credentials/configure-container-repository-credentials-acr-iam.png)

 备注

对于用户分配的托管标识，请跳过此步骤。 如果规模集只与一个用户分配的托管标识相关联，则以下剩余步骤的作用相同。

1. 向虚拟机规模集授予从注册表中拉取/读取映像的权限。 从 Azure 门户中 Azure 容器注册表的“访问控制(IAM)”边栏选项卡中，为虚拟机添加角色分配：

   ![将 VM 主体添加到 ACR](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/configure-container-repository-credentials/configure-container-repository-credentials-vmss-identity.png)

2. 接下来，修改应用程序清单。 在 `ContainerHostPolicies` 部分中，添加属性 `‘UseTokenAuthenticationCredentials=”true”`。

   XML复制

   ```xml
     <ServiceManifestImport>
         <ServiceManifestRef ServiceManifestName="NodeServicePackage" ServiceManifestVersion="1.0"/>
     <Policies>
       <ContainerHostPolicies CodePackageRef="NodeService.Code" Isolation="process" UseTokenAuthenticationCredentials="true">
         <PortBinding ContainerPort="8905" EndpointRef="Endpoint1"/>
       </ContainerHostPolicies>
       <ResourceGovernancePolicy CodePackageRef="NodeService.Code" MemoryInMB="256"/>
     </Policies>
     </ServiceManifestImport>
   ```

    备注

   当 `UseTokenAuthenticationCredentials` 为 true 时，将标志 `UseDefaultRepositoryCredentials` 设置为 true 将导致部署过程中出现错误。







# Azure Service Fabric 中的中心机密存储

本文介绍如何使用 Azure Service Fabric 中的中心机密存储 (CSS) 在 Service Fabric 应用程序中创建机密。 CSS 是一个本地机密存储缓存，用于保存敏感数据，例如，已在内存中加密的密码、令牌和密钥。

 备注

在 SF 版本7.1 之前首次激活 CSS。 CU3，如果在 Windows 身份验证群集上激活了 CSS，激活可能会失败并使 CSS 处于永久性不正常状态：CSS 在任何群集上被激活，但 `EncryptionCertificateThumbprint` 未正确声明或未在节点上安装相应的证书。 对于 Windows 身份验证群集，请转至7.1。 CU3，然后继续。 对于其他群集，请仔细检查这些固定条件，或将其放入7.1。 CU3.

## 启用中心机密存储

将以下脚本添加到群集配置中的 `fabricSettings` 下即可启用 CSS。 对于 CSS，我们建议使用除群集证书以外的证书。 确保在所有节点上安装加密证书，并且 `NetworkService` 对证书的私钥拥有读取权限。

JSON复制

```json
  "fabricSettings": 
  [
      ...
  {
      "name":  "CentralSecretService",
      "parameters":  [
              {
                  "name":  "IsEnabled",
                  "value":  "true"
              },
              {
                  "name":  "MinReplicaSetSize",
                  "value":  "1"
              },
              {
                  "name":  "TargetReplicaSetSize",
                  "value":  "3"
              },
               {
                  "name" : "EncryptionCertificateThumbprint",
                  "value": "<thumbprint>"
               }
              ,
              ],
          },
          ]
   }
      ...
   ]
```

## 声明机密资源

可以使用 REST API 创建机密资源。

 备注

如果群集使用 Windows 身份验证，则 REST 请求会通过不安全的 HTTP 通道发送。 建议使用具有安全终结点的基于 X509 的群集。

若要使用 REST API 创建 `supersecret` 机密资源，请向 `https://<clusterfqdn>:19080/Resources/Secrets/supersecret?api-version=6.4-preview` 发出 PUT 请求。 需要提供群集证书或管理客户端证书来创建机密资源。

PowerShell复制

```powershell
$json = '{"properties": {"kind": "inlinedValue", "contentType": "text/plain", "description": "supersecret"}}'
Invoke-WebRequest  -Uri https://<clusterfqdn>:19080/Resources/Secrets/supersecret?api-version=6.4-preview -Method PUT -CertificateThumbprint <CertThumbprint> -Body $json
```

## 设置机密值

使用以下 REST API 脚本设置机密值。

PowerShell复制

```powershell
$Params = '{"properties": {"value": "mysecretpassword"}}'
Invoke-WebRequest -Uri https://<clusterfqdn>:19080/Resources/Secrets/supersecret/values/ver1?api-version=6.4-preview -Method PUT -Body $Params -CertificateThumbprint <ClusterCertThumbprint>
```

### 检查机密值

PowerShell复制

```powershell
Invoke-WebRequest -CertificateThumbprint <ClusterCertThumbprint> -Method POST -Uri "https:<clusterfqdn>/Resources/Secrets/supersecret/values/ver1/list_value?api-version=6.4-preview"
```

## 在应用程序中使用机密

遵循以下步骤在 Service Fabric 应用程序中使用机密。

1. 在 **settings.xml** 文件中添加包含以下代码片段的节。 请注意，此处的值采用 {`secretname:version`} 格式。

   XML复制

   ```xml
     <Section Name="testsecrets">
      <Parameter Name="TopSecret" Type="SecretsStoreRef" Value="supersecret:ver1"/
     </Section>
   ```

2. 将该节导入到 **ApplicationManifest.xml** 中。

   XML复制

   ```xml
     <ServiceManifestImport>
       <ServiceManifestRef ServiceManifestName="testservicePkg" ServiceManifestVersion="1.0.0" />
       <ConfigOverrides />
       <Policies>
         <ConfigPackagePolicies CodePackageRef="Code">
           <ConfigPackage Name="Config" SectionName="testsecrets" EnvironmentVariableName="SecretPath" />
           </ConfigPackagePolicies>
       </Policies>
     </ServiceManifestImport>
   ```

   环境变量 `SecretPath` 将指向存储所有机密的目录。 `testsecrets` 节下列出的每个参数存储在单独的文件中。 现在，应用程序可以使用该机密，如下所示：

   C#复制

   ```C#
   secretValue = IO.ReadFile(Path.Join(Environment.GetEnvironmentVariable("SecretPath"),  "TopSecret"))
   ```

3. 将机密装载到容器。 使机密在容器中可用而要做出的唯一更改就是在 `<ConfigPackage>` 中指定 (`specify`) 一个装入点。 以下代码片段是修改后的 **ApplicationManifest.xml**。

   XML复制

   ```xml
   <ServiceManifestImport>
       <ServiceManifestRef ServiceManifestName="testservicePkg" ServiceManifestVersion="1.0.0" />
       <ConfigOverrides />
       <Policies>
         <ConfigPackagePolicies CodePackageRef="Code">
           <ConfigPackage Name="Config" SectionName="testsecrets" MountPoint="C:\secrets" EnvironmentVariableName="SecretPath" />
           <!-- Linux Container
            <ConfigPackage Name="Config" SectionName="testsecrets" MountPoint="/mnt/secrets" EnvironmentVariableName="SecretPath" />
           -->
         </ConfigPackagePolicies>
       </Policies>
     </ServiceManifestImport>
   ```

   可在容器中的装入点下使用机密。

4. 可以通过指定 `Type='SecretsStoreRef` 将机密绑定到进程环境变量。 以下示例代码片段演示如何将 `supersecret` 版本 `ver1` 绑定到 **ServiceManifest.xml** 中的环境变量 `MySuperSecret`。

   XML复制

   ```xml
   <EnvironmentVariables>
     <EnvironmentVariable Name="MySuperSecret" Type="SecretsStoreRef" Value="supersecret:ver1"/>
   </EnvironmentVariables>
   ```





# Azure Service Fabric 中的 DNS 服务

DNS 服务是可选的系统服务，可以在群集中启用，用于发现使用 DNS 协议的其他服务。

许多服务（特别是容器化服务）可以通过现存的 URL 来寻址。 能够使用标准 DNS 协议（而不是 Service Fabric 命名服务协议）解析这些名称是很有必要的。 借助 DNS 服务，可将 DNS 名称映射到服务名称，进而解析终结点 IP 地址。 此类功能可在不同的平台之间保持容器化服务的可移植性，并更方便地利用“直接迁移”方案，因为它可以让你使用现有的服务 URL，而无需重新编写代码来利用命名服务。

DNS 服务将 DNS 名称映射到服务名称，命名服务将服务名称进行解析并将其发送回服务终结点。 在创建时提供服务的 DNS 名称。 下图显示了如何对无状态服务运行 DNS 服务。

![显示 dns 服务如何为无状态服务将 DNS 名称映射到服务名称的关系图。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-dnsservice/stateless-dns.png)

从 Service Fabric 版本 6.3 开始，Service Fabric DNS 协议经过扩展，现在包含用于寻址已分区的有状态服务的方案。 使用这些扩展可以通过有状态服务 DNS 名称和分区名称的组合来解析特定的分区 IP 地址。 支持所有三种分区方案：

- 命名分区
- 按范围分区
- 单一实例分区

下图显示了如何分区的有状态服务运行 DNS 服务。

![显示已分区无状态服务的 dns 服务将 DNS 名称映射到服务名称的关系图。](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-dnsservice/stateful-dns.png)

DNS 服务不支持动态端口。 若要解析动态端口上公开的服务，请使用[反向代理服务](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-reverseproxy)。

## 启用 DNS 服务

 备注

在 Linux 上尚不支持用于 Service Fabric 服务的 DNS 服务。

使用门户创建群集时，默认情况下，在“群集配置”菜单的“包括 DNS 服务”复选框中启用 DNS 服务 ：

![通过门户启用 DNS 服务](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-dnsservice/enable-dns-service.png)

如果不使用门户创建群集或者要更新现有群集，则需要在模板中启用 DNS 服务：

- 若要部署新的群集，可以使用[示例模板](https://github.com/Azure/azure-quickstart-templates/tree/master/service-fabric-secure-cluster-5-node-1-nodetype)或创建自己的资源管理器模板。
- 若要更新现有群集，可以导航到门户的群集资源组并单击“自动化脚本”，使用反映群集和组中其他资源当前状态的模板 。 若要了解详细信息，请参阅[从资源组导出模板](https://docs.microsoft.com/zh-cn/azure/azure-resource-manager/templates/export-template-portal)。

有了模板后，可以通过以下步骤启用 DNS 服务：

1. 检查 `Microsoft.ServiceFabric/clusters` 资源的 `apiversion` 是否设置为 `2017-07-01-preview` 或更高，如果不是，请按以下示例所示进行更新：

   JSON复制

   ```json
   {
       "apiVersion": "2017-07-01-preview",
       "type": "Microsoft.ServiceFabric/clusters",
       "name": "[parameters('clusterName')]",
       "location": "[parameters('clusterLocation')]",
       ...
   }
   ```

2. 现在，通过以下方式之一启用 DNS 服务：

   - 若要启用采用默认设置的 DNS 服务，请将其添加到 `properties` 节中的 `addonFeatures` 节，如以下示例所示：

     JSON复制

     ```json
       "properties": {
         ...
         "addonFeatures": [
           "DnsService"
           ],
         ...
       }
     ```

   - 若要启用采用非默认设置的服务，请将 `DnsService` 节添加到 `properties` 节中的 `fabricSettings` 节。 在这种情况下，不需要将 DnsService 添加到 `addonFeatures`。 若要详细了解可为 DNS 服务设置的属性，请参阅 [DNS 服务设置](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-cluster-fabric-settings#dnsservice)。

     JSON复制

     ```json
         "properties": {
           ...  
           "fabricSettings": [
             ...
             {
               "name": "DnsService",
               "parameters": [
                 {
                   "name": "IsEnabled",
                   "value": "true"
                 },
                 {
                   "name": "PartitionSuffix",
                   "value": "--"
                 },
                 {
                   "name": "PartitionPrefix",
                   "value": "--"
                 }
               ]
             },
             ...
            ]
          }
     ```

3. 通过这些更改更新群集模板后，请应用更改并等待升级完成。 完成升级后，DNS 系统服务将开始在群集中运行。 服务名称是 `fabric:/System/DnsService`，可以在 Service Fabric Explorer 的“系统”服务部分下找到它 。

 备注

将 DNS 从禁用升级到启用时，Service Fabric Explorer 可能未反映新状态。 若要解决问题，请重启节点，方法是：在 Azure 资源管理器模板中修改 UpgradePolicy。 有关详细信息，请参阅 [Service Fabric 模板参考](https://docs.microsoft.com/zh-cn/azure/templates/microsoft.servicefabric/2019-03-01/clusters/applications)。

 备注

在本地计算机上进行开发时，如果启用 DNS 服务，则会替代某些 DNS 设置。 如果在连接到 Internet 时遇到问题，请检查 DNS 设置。

## 设置服务的 DNS 名称

可以在 ApplicationManifest.xml 文件中或者通过 PowerShell 命令，以声明方式为默认服务设置 DNS 名称。

服务的 DNS 名称可在整个群集中解析，因此，请务必确保 DNS 名称在整个群集中的唯一性。

强烈建议使用 `<ServiceDnsName>.<AppInstanceName>` 命名方案；例如 `service1.application1`。 如果使用 Docker Compose 部署应用程序，服务会自动分配使用此命名方案的 DNS 名称。

### 在 ApplicationManifest.xml 中为默认服务设置 DNS 名称

在 Visual Studio 中或所选的编辑器中打开项目，并打开 ApplicationManifest.xml 文件。 转到默认服务部分，为每个服务添加 `ServiceDnsName` 属性。 以下示例说明如何将服务的 DNS 名称设置为 `service1.application1`

XML复制

```xml
    <Service Name="Stateless1" ServiceDnsName="service1.application1">
      <StatelessService ServiceTypeName="Stateless1Type" InstanceCount="[Stateless1_InstanceCount]">
        <SingletonPartition />
      </StatelessService>
    </Service>
```

部署应用程序后，Service Fabric Explorer 中的服务实例会显示此实例的 DNS 名称，如下图所示：

![服务终结点](https://docs.microsoft.com/zh-cn/azure/service-fabric/media/service-fabric-dnsservice/service-fabric-explorer-dns.png)

以下示例将有状态服务的 DNS 名称设置为 `statefulsvc.app`。 该服务使用命名分区方案。 请注意分区名称均为小写。 这是在 DNS 查询中用作目标的分区的一项要求；有关详细信息，请参阅[针对有状态服务分区发出 DNS 查询](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-dnsservice#preview-making-dns-queries-on-a-stateful-service-partition)。

XML复制

```xml
    <Service Name="Stateful1" ServiceDnsName="statefulsvc.app" />
      <StatefulService ServiceTypeName="ProcessingType" TargetReplicaSetSize="2" MinReplicaSetSize="2">
        <NamedPartition>
         <Partition Name="partition1" />
         <Partition Name="partition2" />
        </NamedPartition>
      </StatefulService>
    </Service>
```

### 使用 Powershell 设置服务的 DNS 名称

创建服务时，可以使用 `New-ServiceFabricService` Powershell 命令设置服务的 DNS 名称。 以下示例创建一个 DNS 名称为 `service1.application1` 的新的无状态服务

PowerShell复制

```powershell
    New-ServiceFabricService `
    -Stateless `
    -PartitionSchemeSingleton `
    -ApplicationName `fabric:/application1 `
    -ServiceName fabric:/application1/service1 `
    -ServiceTypeName Service1Type `
    -InstanceCount 1 `
    -ServiceDnsName service1.application1
```

## [预览版] 针对有状态服务分区发出 DNS 查询

从 Service Fabric 版本 6.3 开始，Service Fabric DNS 服务支持针对服务分区的查询。

对于 DNS 查询中使用的分区，适用以下命名限制：

- 分区名称应符合 DNS 规范。
- 不应使用多标签分区名称（名称中包括句点“.”）。
- 分区名称应为小写。

针对分区的 DNS 查询的格式如下：

复制

```
    <First-Label-Of-Partitioned-Service-DNSName><PartitionPrefix><Target-Partition-Name>< PartitionSuffix>.<Remaining- Partitioned-Service-DNSName>
```

其中：

- *First-Label-Of-Partitioned-Service-DNSName* 是服务 DNS 名称的第一个部分。
- *PartitionPrefix* 是可以在群集清单的 DnsService 节中设置的，或者通过群集资源管理器模板设置的值。 默认值为“--”。 有关详细信息，请参阅 [DNS 服务设置](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-cluster-fabric-settings#dnsservice)。
- *Target-Partition-Name* 是分区的名称。
- *PartitionSuffix* 是可以在群集清单的 DnsService 节中设置的，或者通过群集资源管理器模板设置的值。 默认值为空字符串。 有关详细信息，请参阅 [DNS 服务设置](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-cluster-fabric-settings#dnsservice)。
- *Remaining-Partitioned-Service-DNSName* 是服务 DNS 名称的剩余部分。

以下示例显示了针对某个群集（该群集对 `PartitionPrefix` 和 `PartitionSuffix` 采用默认设置）上运行的分区服务发出的 DNS 查询：

- 若要解析具有 DNS 名称 `backendrangedschemesvc.application`（使用按范围分区方案）的服务的分区“0”，请使用 `backendrangedschemesvc-0.application`。
- 若要解析具有 DNS 名称 `backendnamedschemesvc.application`（使用命名分区方案）的服务的分区“first”，请使用 `backendnamedschemesvc-first.application`。

DNS 服务将返回该分区的主要副本的 IP 地址。 如果未指定分区，服务将返回随机选择的分区的主要副本的 IP 地址。

## 在服务中使用 DNS

如果部署多个服务，可以使用 DNS 名称找到用于通信的其他服务的终结点。 DNS 服务适用于无状态服务，在 Service Fabric 版本 6.3 和更高版本中，它也适用于有状态服务。 对于运行低于 Service Fabric 6.3 版本的 有状态服务，可以使用 HTTP 调用的内置[反向代理服务](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-reverseproxy)调用特定的服务分区。

DNS 服务不支持动态端口。 可以通过反向代理服务解析使用动态端口的服务。

以下代码演示如何通过 DNS 调用无状态服务。 它只是一个普通的 http 调用，其中提供了 DNS 名称、端口和任一可选路径作为 URL 的一部分。

C#复制

```csharp
public class ValuesController : Controller
{
    // GET api
    [HttpGet]
    public async Task<string> Get()
    {
        string result = "";
        try
        {
            Uri uri = new Uri("http://service1.application1:8080/api/values");
            HttpClient client = new HttpClient();
            var response = await client.GetAsync(uri);
            result = await response.Content.ReadAsStringAsync();
            
        }
        catch (Exception e)
        {
            Console.Write(e.Message);
        }

        return result;
    }
}
```

以下代码演示如何调用有状态服务的特定分区。 在本例中，DNS 名称包含分区名称 (partition1)。 该调用假设群集对`PartitionPrefix` 和 `PartitionSuffix` 使用默认值。

C#复制

```csharp
public class ValuesController : Controller
{
    // GET api
    [HttpGet]
    public async Task<string> Get()
    {
        string result = "";
        try
        {
            Uri uri = new Uri("http://service2-partition1.application1:8080/api/values");
            HttpClient client = new HttpClient();
            var response = await client.GetAsync(uri);
            result = await response.Content.ReadAsStringAsync();
            
        }
        catch (Exception e)
        {
            Console.Write(e.Message);
        }

        return result;
    }
}
```

## 已知问题

- 对于 Service Fabric 版本 6.3 及更高版本，对于 DNS 名称中包含连字符的服务名称，DNS 查找存在问题。 有关此问题的详细信息，请跟踪以下 [GitHub 问题](https://github.com/Azure/service-fabric-issues/issues/1197)。 此问题的修补程序将在接下来的 6.3 更新中提供。
- 在 Linux 上尚不支持用于 Service Fabric 服务的 DNS 服务。 Linux 上的容器支持 DNS 服务。 使用 Fabric 客户端/ServicePartitionResolver 进行手动解析是另一种选择。

# Service Fabric 应用程序和服务清单

本文介绍如何使用 ApplicationManifest.xml 和 ServiceManifest.xml 文件定义 Service Fabric 应用程序和服务并对其进行版本控制。 有关更多详细示例，请参阅[应用程序和服务清单示例](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-examples)。 这些清单文件的 XML 架构记录在 [ServiceFabricServiceModel.xsd 架构文档](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-service-model-schema)中。

 警告

清单 XML 文件架构强制对子元素进行正确排序。 作为局部解决方法，创作或修改任何 Service Fabric 清单时，请在 Visual Studio中打开“C:\Program Files\Microsoft SDKs\Service Fabric\schemas\ServiceFabricServiceModel.xsd”。 这样一来，可以检查子元素的排序并提供 intelli-sense。

## 使用 ServiceManifest.xml 描述服务

服务清单以声明方式定义服务类型和版本。 它指定服务元数据，例如服务类型、运行状况属性、负载均衡度量值、服务二进制文件和配置文件。 换言之，它描述了组成一个服务包以支持一个或多个服务类型的代码、配置和数据包。 服务清单可以包含多个代码、配置和数据包，可以独立进行版本控制。 以下是[投票示例应用程序](https://github.com/Azure-Samples/service-fabric-dotnet-quickstart)的 ASP.NET Core Web 前端服务的服务清单（以下是一些[更详细的示例](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-examples)）：

XML复制

```xml
<?xml version="1.0" encoding="utf-8"?>
<ServiceManifest Name="VotingWebPkg"
                 Version="1.0.0"
                 xmlns="http://schemas.microsoft.com/2011/01/fabric"
                 xmlns:xsd="https://www.w3.org/2001/XMLSchema"
                 xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance">
  <ServiceTypes>
    <!-- This is the name of your ServiceType. 
         This name must match the string used in RegisterServiceType call in Program.cs. -->
    <StatelessServiceType ServiceTypeName="VotingWebType" />
  </ServiceTypes>

  <!-- Code package is your service executable. -->
  <CodePackage Name="Code" Version="1.0.0">
    <EntryPoint>
      <ExeHost>
        <Program>VotingWeb.exe</Program>
        <WorkingFolder>CodePackage</WorkingFolder>
      </ExeHost>
    </EntryPoint>
  </CodePackage>

  <!-- Config package is the contents of the Config directory under PackageRoot that contains an 
       independently-updateable and versioned set of custom configuration settings for your service. -->
  <ConfigPackage Name="Config" Version="1.0.0" />

  <Resources>
    <Endpoints>
      <!-- This endpoint is used by the communication listener to obtain the port on which to 
           listen. Please note that if your service is partitioned, this port is shared with 
           replicas of different partitions that are placed in your code. -->
      <Endpoint Protocol="http" Name="ServiceEndpoint" Type="Input" Port="8080" />
    </Endpoints>
  </Resources>
</ServiceManifest>
```

**Version** 特性是未结构化的字符串，并且不由系统进行分析。 版本特性用于对每个组件进行版本控制，以进行升级。

**ServiceTypes** 声明此清单中的 **CodePackages** 支持哪些服务类型。 当一种服务针对这些服务类型之一进行实例化时，可激活此清单中声明的所有代码包，方法是运行这些代码包的入口点。 生成的进程应在运行时注册所支持的服务类型。 在清单级别而不是代码包级别声明服务类型。 因此，当存在多个代码包时，每当系统查找任何一种声明的服务类型时，它们都会被激活。

**EntryPoint** 指定的可执行文件通常是长时间运行的服务主机。 **SetupEntryPoint** 是特权入口点，以与 Service Fabric（通常是 *LocalSystem* 帐户）相同的凭据先于任何其他入口点运行。 提供单独的设置入口点可避免长时间使用高特权运行服务主机。 由 **EntryPoint** 指定的可执行文件在 **SetupEntryPoint** 成功退出后运行。 如果进程总是终止或出现故障，则监视并重启所产生的过程（再次从“SetupEntryPoint”开始 ）。

“SetupEntryPoint”的典型使用场景是在服务启动之前运行可执行文件，或使用提升的权限来执行操作时 。 例如：

- 设置和初始化服务可执行文件所需的环境变量。 这并不限于通过 Service Fabric 编程模型编写的可执行文件。 例如，npm.exe 需要配置一些环境变量来部署 node.js 应用程序。
- 通过安装安全证书设置访问控制。

有关如何配置 SetupEntryPoint 的详细信息，请参阅[配置服务设置入口点的策略](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-runas-security)

**EnvironmentVariables**（上一示例中未设置），提供为此代码包设置的环境变量列表。 环境变量可以在 `ApplicationManifest.xml` 中重写，以便为不同的服务实例提供不同的值。

**DataPackage**（上一示例中未设置），声明一个由 Name 属性命名的文件夹，该文件夹中包含进程会在运行时使用的任意静态数据 。

**ConfigPackage** 声明一个由 **Name** 特性命名的文件夹，该文件夹中包含 *Settings.xml* 文件。 此设置文件包含用户定义的键值对设置部分，进程可在运行时读回这些设置。 升级期间，如果仅更改了 **ConfigPackage** **版本**，则不重启正在运行的进程。 相反，回调会向进程通知配置设置已更改，以便可以重新动态加载这些设置。 下面是 *Settings.xml* 文件的一个示例：

XML复制

```xml
<Settings xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" xmlns="http://schemas.microsoft.com/2011/01/fabric">
  <Section Name="MyConfigurationSection">
    <Parameter Name="MySettingA" Value="Example1" />
    <Parameter Name="MySettingB" Value="Example2" />
  </Section>
</Settings>
```

Service Fabric 服务“终结点” 是 Service Fabric 资源的一个示例。 无需更改已编译的代码，即可声明/更改 Service Fabric 资源。 可以通过应用程序清单中的 SecurityGroup 控制对服务清单中指定 Service Fabric 资源的访问 。 在服务清单中定义了终结点资源时，如果未显式指定端口，则 Service Fabric 从保留的应用程序端口范围中分配端口。 详细了解[指定或替代终结点资源](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-service-manifest-resources)。

 警告

根据设计，静态端口不应与 ClusterManifest 中指定的应用程序端口范围重叠。 如果指定静态端口，请将其分配到应用程序端口范围外，否则会导致端口冲突。 对于版本 6.5CU2，当我们检测到此类冲突时，我们将发出**运行状况警告**，但让部署继续与已发布的 6.5 行为同步。 但是，我们可能会在下一个主要版本中阻止应用程序部署。

## 使用 ApplicationManifest.xml 描述应用程序

应用程序清单以声明方式描述应用程序类型和版本。 它指定服务组合元数据（如稳定名称、分区方案、实例计数/复制因子、安全/隔离策略、布置约束、配置替代和成分服务类型）。 此外还描述了会在其中放置应用程序的负载均衡域。

因此，应用程序清单在应用程序级别描述元素，并引用了一个或多个服务清单，以组成应用程序类型。 以下是[投票示例应用程序](https://github.com/Azure-Samples/service-fabric-dotnet-quickstart)的应用程序清单（以下是一些[更详细的示例](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-examples)）：

XML复制

```xml
<?xml version="1.0" encoding="utf-8"?>
<ApplicationManifest xmlns:xsd="https://www.w3.org/2001/XMLSchema" xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance" ApplicationTypeName="VotingType" ApplicationTypeVersion="1.0.0" xmlns="http://schemas.microsoft.com/2011/01/fabric">
  <Parameters>
    <Parameter Name="VotingData_MinReplicaSetSize" DefaultValue="3" />
    <Parameter Name="VotingData_PartitionCount" DefaultValue="1" />
    <Parameter Name="VotingData_TargetReplicaSetSize" DefaultValue="3" />
    <Parameter Name="VotingWeb_InstanceCount" DefaultValue="-1" />
  </Parameters>
  <!-- Import the ServiceManifest from the ServicePackage. The ServiceManifestName and ServiceManifestVersion 
       should match the Name and Version attributes of the ServiceManifest element defined in the 
       ServiceManifest.xml file. -->
  <ServiceManifestImport>
    <ServiceManifestRef ServiceManifestName="VotingDataPkg" ServiceManifestVersion="1.0.0" />
    <ConfigOverrides />
  </ServiceManifestImport>
  <ServiceManifestImport>
    <ServiceManifestRef ServiceManifestName="VotingWebPkg" ServiceManifestVersion="1.0.0" />
    <ConfigOverrides />
  </ServiceManifestImport>
  <DefaultServices>
    <!-- The section below creates instances of service types, when an instance of this 
         application type is created. You can also create one or more instances of service type using the 
         ServiceFabric PowerShell module.
         
         The attribute ServiceTypeName below must match the name defined in the imported ServiceManifest.xml file. -->
    <Service Name="VotingData">
      <StatefulService ServiceTypeName="VotingDataType" TargetReplicaSetSize="[VotingData_TargetReplicaSetSize]" MinReplicaSetSize="[VotingData_MinReplicaSetSize]">
        <UniformInt64Partition PartitionCount="[VotingData_PartitionCount]" LowKey="0" HighKey="25" />
      </StatefulService>
    </Service>
    <Service Name="VotingWeb" ServicePackageActivationMode="ExclusiveProcess">
      <StatelessService ServiceTypeName="VotingWebType" InstanceCount="[VotingWeb_InstanceCount]">
        <SingletonPartition />
         <PlacementConstraints>(NodeType==NodeType0)</PlacementConstraints
      </StatelessService>
    </Service>
  </DefaultServices>
</ApplicationManifest>
```

类似于服务清单，**Version** 特性是未结构化的字符串，并且不由系统进行分析。 版本特性也用于对每个组件进行版本控制，以进行升级。

**Parameters**，定义整个应用程序清单中使用的参数。 当应用程序已实例化并可替代应用程序或服务配置设置时，可以提供这些参数的值。 如果在应用程序实例化期间该值未更改，则使用默认参数值。 若要了解如何维护不同的应用程序和用于单个环境的服务参数，请参阅[管理多个环境的应用程序参数](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manage-multiple-environment-app-configuration)。

**ServiceManifestImport** 包含对组成此应用程序类型的服务清单的引用。 应用程序清单可以包含多个服务清单导入，每个导入都可独立进行版本控制。 导入的服务清单将确定此应用程序类型中哪些服务类型有效。 在 ServiceManifestImport 中，可以重写 Settings.xml 中的配置值和 ServiceManifest.xml 文件中的环境变量。 **Policies**（上一示例中未设置），用于终结点绑定、安全性和访问以及包共享，可以在导入的服务清单上进行设置。 有关详细信息，请参阅[配置应用程序的安全策略](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-runas-security)。

**DefaultServices** 声明每当一个应用程序依据此应用程序类型进行实例化时自动创建的服务实例。 默认服务只是提供便利，创建后，它们的行为在每个方面都与常规服务类似。 它们与应用程序实例中的任何其他服务一起升级，并且也可以将它们删除。 应用程序清单可以包含多个默认服务。

**Certificates**（上一示例中未设置），声明用于[设置 HTTPS 终结点](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-service-manifest-resources#example-specifying-an-https-endpoint-for-your-service)或用于[加密应用程序清单中的机密](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-secret-management)的证书。

**放置约束**是定义服务运行位置的语句。 这些语句将附加到你为一个或多个节点属性选择的各个服务。 有关详细信息，请参阅[放置约束和节点属性语法](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-cluster-resource-manager-cluster-description#placement-constraints-and-node-property-syntax)

**Policies**（在前面的示例中未设置）描述要在应用程序级别设置的日志收集、[默认运行方式帐户](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-runas-security)、[运行状况](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-health-introduction#health-policies)和[安全访问](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-runas-security)策略，包括服务是否可以访问 Service Fabric 运行时。

 备注

默认情况下，Service Fabric 应用程序可以通过以下形式访问 Service Fabric 运行时：终结点（接受应用程序特定请求）和环境变量（指向包含 Fabric 和应用程序特定文件的主机上的文件路径）。 在应用程序托管不受信任的代码（即其出处未知或应用程序所有者知道其执行起来不安全）时，请考虑禁止进行此访问。 有关详细信息，请参阅 [Service Fabric 中的安全最佳做法](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-best-practices-security#platform-isolation)。

**Principals**（上一示例中未设置），描述[运行服务并确保服务资源安全](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-runas-security)所需的安全主体（用户或组）。 Policies 部分中会引用 Principals 。

# Service Fabric 应用程序和服务清单示例

本部分包含应用程序和服务清单的示例。 这些示例并非用来展示重要方案，而是用来展示可用的各种设置以及如何使用它们。

下面是所显示的功能以及它们所属的示例清单的索引。

| Feature                                                      | 清单                                                         |
| :----------------------------------------------------------- | :----------------------------------------------------------- |
| [资源调控](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-resource-governance) | [Reliable Services 应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-reliable-services-app#application-manifest)、[容器应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#application-manifest) |
| [以本地管理帐户身份运行服务](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-runas-security) | [Reliable Services 应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-reliable-services-app#application-manifest) |
| [将默认策略应用于所有服务代码包](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-runas-security#apply-a-default-policy-to-all-service-code-packages) | [Reliable Services 应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-reliable-services-app#application-manifest) |
| [创建用户和组主体](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-runas-security) | [Reliable Services 应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-reliable-services-app#application-manifest) |
| 在服务实例之间共享数据包                                     | [Reliable Services 应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-reliable-services-app#application-manifest) |
| [替代服务终结点](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-service-manifest-resources#overriding-endpoints-in-servicemanifestxml) | [Reliable Services 应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-reliable-services-app#application-manifest) |
| [在服务启动时运行脚本](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-run-script-at-service-startup) | [VotingWeb 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-reliable-services-app#votingweb-service-manifest) |
| [定义 HTTPS 终结点](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-tutorial-dotnet-app-enable-https-endpoint#define-an-https-endpoint-in-the-service-manifest) | [VotingWeb 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-reliable-services-app#votingweb-service-manifest) |
| [声明配置包](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-and-service-manifests) | [VotingData 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-reliable-services-app#votingdata-service-manifest) |
| [声明数据包](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-and-service-manifests) | [VotingData 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-reliable-services-app#votingdata-service-manifest) |
| [替代环境变量](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-get-started-containers#configure-and-set-environment-variables) | [容器应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#application-manifest) |
| [配置容器端口到主机映射](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-get-started-containers#configure-container-port-to-host-port-mapping-and-container-to-container-discovery) | [容器应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#application-manifest) |
| [配置容器注册表身份验证](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-get-started-containers#configure-container-repository-authentication) | [容器应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#application-manifest) |
| [设置隔离模式](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-get-started-containers#configure-isolation-mode) | [容器应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#application-manifest) |
| [指定特定于 OS 内部版本的容器映像](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-get-started-containers#specify-os-build-specific-container-images) | [容器应用程序清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#application-manifest) |
| [设置环境变量](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-get-started-containers#configure-and-set-environment-variables) | [容器 FrontEndService 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#frontendservice-service-manifest)、[容器 BackEndService 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#backendservice-service-manifest) |
| [配置终结点](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-get-started-containers#configure-communication) | [容器 FrontEndService 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#frontendservice-service-manifest)、[容器 BackEndService 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#backendservice-service-manifest)、[VotingData 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-reliable-services-app#votingdata-service-manifest) |
| 将命令传递到容器                                             | [容器 FrontEndService 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#frontendservice-service-manifest) |
| [将证书导入到容器中](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-securing-containers) | [容器 FrontEndService 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#frontendservice-service-manifest) |
| [配置卷驱动程序](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-containers-volume-logging-drivers) | [容器 BackEndService 服务清单](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-manifest-example-container-app#backendservice-service-manifest) |



# 适用于 Service Fabric 的 Azure 文件存储卷驱动程序



Azure 文件存储卷驱动程序是一个 [Docker 卷插件](https://docs.docker.com/engine/extend/plugins_volume/)，可为 Docker 容器提供基于 [Azure 文件存储](https://docs.microsoft.com/zh-cn/azure/storage/files/storage-files-introduction)的卷。 它将打包为 Service Fabric 应用程序，可以部署到 Service Fabric 群集以为群集内的其他 Service Fabric 容器应用程序提供卷。

 备注

Azure 文件存储卷插件版本6.5.661.9590 已正式发布。

## 必备条件

- Windows 版 Azure 文件卷插件仅适用于 [Windows Server 1709 版](https://docs.microsoft.com/zh-cn/windows-server/get-started/whats-new-in-windows-server-1709)、[Windows 10 1709 版](https://docs.microsoft.com/zh-cn/windows/whats-new/whats-new-windows-10-version-1709)或更高版本的操作系统。
- Linux 版 Azure 文件卷插件适用于 Service Fabric 支持的所有操作系统版本。
- Azure 文件卷插件仅适用于 Service Fabric 6.2 和更高版本。
- 按照 [Azure 文件文档](https://docs.microsoft.com/zh-cn/azure/storage/files/storage-how-to-create-file-share)中的说明，为要用作卷的 Service Fabric 容器应用程序创建文件共享。
- 需要[具有 Service Fabric 模块的 Powershell](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-get-started) 或安装 [SFCTL](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-cli)。
- 如果使用的是 Hyper-V 容器，则需要在 Azure 资源管理器模板（Azure 群集）或 ClusterConfig.json（独立群集）的 ClusterManifest（本地群集）或 fabricSettings 节中添加以下代码片段。

在 ClusterManifest 中，需要在“Hosting”节中添加以下内容。 在此示例中，卷名为 **sfazurefile**，它在群集上侦听的端口为 **19100**。 请将它们替换为你的群集的正确值。

XML复制

```xml
<Section Name="Hosting">
  <Parameter Name="VolumePluginPorts" Value="sfazurefile:19100" />
</Section>
```

在 Azure 资源管理器模板（适用于 Azure 部署）或 ClusterConfig.json（适用于独立部署）的 fabricSettings 节中，需要添加以下代码片段。 同样，将卷名和端口值替换为你自己的值。

JSON复制

```json
"fabricSettings": [
  {
    "name": "Hosting",
    "parameters": [
      {
          "name": "VolumePluginPorts",
          "value": "sfazurefile:19100"
      }
    ]
  }
]
```

## 使用 Service Fabric Azure 文件存储卷驱动程序部署示例应用程序

### 通过提供的 Powershell 脚本使用 Azure 资源管理器（建议）

如果群集基于 Azure，建议使用 Azure 资源管理器应用程序资源模型将应用程序部署到群集，既可方便使用，也有助于迁移到将基础结构作为代码进行维护的模型。 此方法不需跟踪 Azure 文件存储卷驱动程序的应用版本。 另外，这样还可以为每个支持的 OS 保留单独的 Azure 资源管理器模板。 脚本假设你部署的是最新版 Azure 文件存储应用程序，而且，脚本获取的是 OS 类型、群集订阅 ID 和资源组的参数。 可从 [Service Fabric 下载站点](https://sfazfilevd.blob.core.windows.net/sfazfilevd/DeployAzureFilesVolumeDriver.zip)下载该脚本。 请注意，这会自动将 ListenPort（Azure 文件存储卷插件从 Docker 守护程序侦听请求的端口）设置为 19100。 可以通过添加名为“listenPort”的参数来更改它。 请确保此端口不与群集或应用程序使用的任何其他端口冲突。

用于 Windows 的 Azure 资源管理器部署命令：

PowerShell复制

```powershell
.\DeployAzureFilesVolumeDriver.ps1 -subscriptionId [subscriptionId] -resourceGroupName [resourceGroupName] -clusterName [clusterName] -windows
```

用于 Linux 的 Azure 资源管理器部署命令：

PowerShell复制

```powershell
.\DeployAzureFilesVolumeDriver.ps1 -subscriptionId [subscriptionId] -resourceGroupName [resourceGroupName] -clusterName [clusterName] -linux
```

成功运行脚本以后，即可跳到[配置应用程序](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-containers-volume-logging-drivers#configure-your-applications-to-use-the-volume)部分。

### 针对独立群集的手动部署

可以从 [Service Fabric 下载站点](https://sfazfilevd.blob.core.windows.net/sfazfilevd/AzureFilesVolumePlugin.6.5.661.9590.zip)下载为容器提供卷的 Service Fabric 应用程序。 可以通过 [PowerShell](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-deploy-remove-applications)、[CLI](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-lifecycle-sfctl) 或 [FabricClient API](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-deploy-remove-applications-fabricclient) 将应用程序部署到群集。

1. 使用命令行，将目录更改为已下载的应用程序包的根目录。

   PowerShell复制

   ```powershell
   cd .\AzureFilesVolume\
   ```

   Bash复制

   ```bash
   cd ~/AzureFilesVolume
   ```

2. 接下来，使用 [ApplicationPackagePath] 和 [ImageStoreConnectionString] 的相应值将应用程序包复制到映像存储区：

   PowerShell复制

   ```powershell
   Copy-ServiceFabricApplicationPackage -ApplicationPackagePath [ApplicationPackagePath] -ImageStoreConnectionString [ImageStoreConnectionString] -ApplicationPackagePathInImageStore AzureFilesVolumePlugin
   ```

   Bash复制

   ```bash
   sfctl cluster select --endpoint https://testcluster.westus.cloudapp.azure.com:19080 --pem test.pem --no-verify
   sfctl application upload --path [ApplicationPackagePath] --show-progress
   ```

3. 注册应用程序类型

   PowerShell复制

   ```powershell
   Register-ServiceFabricApplicationType -ApplicationPathInImageStore AzureFilesVolumePlugin
   ```

   Bash复制

   ```bash
   sfctl application provision --application-type-build-path [ApplicationPackagePath]
   ```

4. 创建应用程序，密切注意 **ListenPort** 应用程序参数值。 该值是 Azure 文件存储卷插件从 Docker 守护程序侦听请求的端口。 请确保提供给应用程序的端口与 ClusterManifest 中的 VolumePluginPorts 匹配，并且不与群集或应用程序使用的任何其他端口冲突。

   PowerShell复制

   ```powershell
   New-ServiceFabricApplication -ApplicationName fabric:/AzureFilesVolumePluginApp -ApplicationTypeName AzureFilesVolumePluginType -ApplicationTypeVersion 6.5.661.9590   -ApplicationParameter @{ListenPort='19100'}
   ```

   Bash复制

   ```bash
   sfctl application create --app-name fabric:/AzureFilesVolumePluginApp --app-type AzureFilesVolumePluginType --app-version 6.5.661.9590  --parameter '{"ListenPort":"19100"}'
   ```

 备注

Windows Server 2016 Datacenter 不支持向容器装载映射 SMB （[仅 Windows Server 1709 版支持](https://docs.microsoft.com/zh-cn/virtualization/windowscontainers/manage-containers/container-storage)）。 这样可以阻止网络卷映射和 Azure 文件卷驱动程序出现在早于 1709 的版本上。

#### 在本地开发群集上部署应用程序

执行[上面](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-containers-volume-logging-drivers#manual-deployment-for-standalone-clusters)的步骤 1-3。

Azure 文件卷插件应用程序的默认服务实例计数为 -1，这表示有一个服务实例会部署到群集中的每个节点。 但在本地开发群集上部署 Azure 文件卷插件应用程序时，服务实例计数应指定为 1。 可以通过 InstanceCount 应用程序参数完成此操作 。 因此，在本地开发群集上创建 Azure 文件存储卷插件应用程序的命令为：

PowerShell复制

```powershell
New-ServiceFabricApplication -ApplicationName fabric:/AzureFilesVolumePluginApp -ApplicationTypeName AzureFilesVolumePluginType -ApplicationTypeVersion 6.5.661.9590  -ApplicationParameter @{ListenPort='19100';InstanceCount='1'}
```

Bash复制

```bash
sfctl application create --app-name fabric:/AzureFilesVolumePluginApp --app-type AzureFilesVolumePluginType --app-version 6.5.661.9590  --parameter '{"ListenPort": "19100","InstanceCount": "1"}'
```

## 配置应用程序以使用卷

以下代码片段演示如何在应用程序清单文件中指定基于 Azure 文件存储的卷。 相关特定元素为 Volume 标记 ：

XML复制

```xml
?xml version="1.0" encoding="UTF-8"?>
<ApplicationManifest ApplicationTypeName="WinNodeJsApp" ApplicationTypeVersion="1.0" xmlns="http://schemas.microsoft.com/2011/01/fabric" xmlns:xsi="https://www.w3.org/2001/XMLSchema-instance">
    <Description>Calculator Application</Description>
    <Parameters>
      <Parameter Name="ServiceInstanceCount" DefaultValue="3"></Parameter>
      <Parameter Name="MyCpuShares" DefaultValue="3"></Parameter>
      <Parameter Name="MyStorageVar" DefaultValue="c:\tmp"></Parameter>
    </Parameters>
    <ServiceManifestImport>
        <ServiceManifestRef ServiceManifestName="NodeServicePackage" ServiceManifestVersion="1.0"/>
     <Policies>
       <ContainerHostPolicies CodePackageRef="NodeService.Code" Isolation="hyperv">
            <PortBinding ContainerPort="8905" EndpointRef="Endpoint1"/>
            <RepositoryCredentials PasswordEncrypted="false" Password="****" AccountName="test"/>
            <Volume Source="azfiles" Destination="c:\VolumeTest\Data" Driver="sfazurefile">
                <DriverOption Name="shareName" Value="" />
                <DriverOption Name="storageAccountName" Value="" />
                <DriverOption Name="storageAccountKey" Value="" />
                <DriverOption Name="storageAccountFQDN" Value="" />
            </Volume>
       </ContainerHostPolicies>
   </Policies>
    </ServiceManifestImport>
    <ServiceTemplates>
        <StatelessService ServiceTypeName="StatelessNodeService" InstanceCount="5">
            <SingletonPartition></SingletonPartition>
        </StatelessService>
    </ServiceTemplates>
</ApplicationManifest>
```

Azure 文件卷插件的驱动程序名称为 sfazurefile 。 此值为应用程序清单中 Volume 标记元素的 Driver 属性而设置 。

在上述代码片段的 Volume 标记中，Azure 文件存储卷插件需要以下属性 ：

- **Source** - 这是卷的名称。 用户可以为其卷选取任何名称。
- **Destination** - 此属性是卷在运行的容器中映射到的位置。 因此，目标不能为容器中的现有位置

如上文代码段中的 DriverOption 元素所示，Azure 文件卷插件支持以下驱动程序选项 ：

- **shareName** - 为容器提供卷的“Azure 文件”文件共享的名称。

- **storageAccountName** - 包含“Azure 文件”文件共享的 Azure 存储帐户的名称。

- **storageAccountKey** - 包含“Azure 文件”文件共享的 Azure 存储帐户的访问密钥。

- **storageAccountFQDN** - 与存储帐户关联的域名。 如果未指定 storageAccountFQDN，则将使用 storageAccountName 的默认后缀 (.file.core.windows.net) 形成域名。

  XML复制

  ```xml
  - Example1: 
      <DriverOption Name="shareName" Value="myshare1" />
      <DriverOption Name="storageAccountName" Value="myaccount1" />
      <DriverOption Name="storageAccountKey" Value="mykey1" />
      <!-- storageAccountFQDN will be "myaccount1.file.core.windows.net" -->
  - Example2: 
      <DriverOption Name="shareName" Value="myshare2" />
      <DriverOption Name="storageAccountName" Value="myaccount2" />
      <DriverOption Name="storageAccountKey" Value="mykey2" />
      <DriverOption Name="storageAccountFQDN" Value="myaccount2.file.core.chinacloudapi.cn" />
  ```

## 使用自己的卷或日志记录驱动程序

Service Fabric 还允许使用自己的自定义[卷](https://docs.docker.com/engine/extend/plugins_volume/)或[日志记录](https://docs.docker.com/engine/admin/logging/overview/)驱动程序。 如果群集上未安装 Docker 卷/日志记录驱动程序，可使用 RDP/SSH 协议手动安装。 还可使用这些协议，通过[虚拟机规模集启动脚本](https://azure.microsoft.com/resources/templates/201-vmss-custom-script-windows/)或 [SetupEntryPoint 脚本](https://docs.microsoft.com/zh-cn/azure/service-fabric/service-fabric-application-model)执行安装操作。

以下是安装 [Azure 的 Docker 卷驱动程序](https://docs.docker.com/docker-for-azure/persistent-data-volumes/)的一个脚本实例：

Bash复制

```bash
docker plugin install --alias azure --grant-all-permissions docker4x/cloudstor:17.09.0-ce-azure1  \
    CLOUD_PLATFORM=AZURE \
    AZURE_STORAGE_ACCOUNT="[MY-STORAGE-ACCOUNT-NAME]" \
    AZURE_STORAGE_ACCOUNT_KEY="[MY-STORAGE-ACCOUNT-KEY]" \
    DEBUG=1
```

在应用程序中，要使用已安装的卷或日志记录驱动程序，则必须在应用程序清单中 ContainerHostPolicies 下方的 Volume 和 LogConfig 元素中指定相应的值 。

XML复制

```xml
<ContainerHostPolicies CodePackageRef="NodeService.Code" Isolation="hyperv">
    <PortBinding ContainerPort="8905" EndpointRef="Endpoint1"/>
    <RepositoryCredentials PasswordEncrypted="false" Password="****" AccountName="test"/>
    <LogConfig Driver="[YOUR_LOG_DRIVER]" >
        <DriverOption Name="test" Value="vale"/>
    </LogConfig>
    <Volume Source="c:\workspace" Destination="c:\testmountlocation1" IsReadOnly="false"></Volume>
    <Volume Source="[MyStorageVar]" Destination="c:\testmountlocation2" IsReadOnly="true"> </Volume>
    <Volume Source="myvolume1" Destination="c:\testmountlocation2" Driver="[YOUR_VOLUME_DRIVER]" IsReadOnly="true">
        <DriverOption Name="[name]" Value="[value]"/>
    </Volume>
</ContainerHostPolicies>
```

指定卷插件时，Service Fabric 使用指定的参数自动创建卷。 “Volume”元素的“Source”标记是卷的名称，“Driver”标记指定卷驱动程序插件 。 “Destination”标记是“Source”在运行的容器中映射到的位置 。 因此，目标不能为容器中的现有位置。 使用 DriverOption 标记可指定选项，如下所示 ：

XML复制

```xml
<Volume Source="myvolume1" Destination="c:\testmountlocation4" Driver="azure" IsReadOnly="true">
           <DriverOption Name="share" Value="models"/>
</Volume>
```

应用程序支持参数卷中前面的清单代码段所示（查找 `MyStorageVar` 有关用法示例）。

如果指定了 Docker 日志记录驱动程序，则需要部署代理（或容器）以处理群集中的日志。 DriverOption 标记可用于指定日志记录驱动程序的选项 。


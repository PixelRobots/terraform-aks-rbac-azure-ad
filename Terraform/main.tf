provider "azurerm" {
    version = "~>1.5"
}

terraform {
    backend "azurerm" {
    }
}

resource "azurerm_resource_group" "k8s" {
  name     = "${var.prefix}-AKS"
  location = "${var.location}"
}

resource "azurerm_virtual_network" "k8s" {
  name                = "${var.prefix}-network"
  location            = "${azurerm_resource_group.k8s.location}"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  address_space       = ["10.101.0.0/16"]
}

resource "azurerm_subnet" "k8s" {
  name                 = "internal"
  resource_group_name  = "${azurerm_resource_group.k8s.name}"
  address_prefix       = "10.101.0.0/24"
  virtual_network_name = "${azurerm_virtual_network.k8s.name}"
}

resource "azurerm_kubernetes_cluster" "k8s" {
  name                = "${var.prefix}-aks"
  location            = "${azurerm_resource_group.k8s.location}"
  dns_prefix          = "${var.prefix}-aks"
  resource_group_name = "${azurerm_resource_group.k8s.name}"
  kubernetes_version  = "${var.kubernetes_version}"

  linux_profile {
    admin_username = "${var.admin_username}"

    ssh_key {
      key_data = "${file(var.public_ssh_key_path)}"
    }
  }

  agent_pool_profile {
    name            = "agentpool"
    count           = "2"
    vm_size         = "Standard_B2s"
    os_type         = "Linux"
    os_disk_size_gb = 30

    # Required for advanced networking
    vnet_subnet_id = "${azurerm_subnet.k8s.id}"
  }

  service_principal {
    client_id     = "${var.client_id}"
    client_secret = "${var.client_secret}"
  }

    tags {
        "ENV" = "TST"
    }

  network_profile {
    network_plugin = "azure"
  }

  role_based_access_control {
    enabled = true
        azure_active_directory {
            server_app_id     = "${var.rbac_server_app_id}"
            server_app_secret = "${var.rbac_server_app_secret}"
            client_app_id     = "${var.rbac_client_app_id}"
            tenant_id         = "${var.tenant_id}"
        }
    }

}
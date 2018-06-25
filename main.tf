# lb
resource "azurerm_public_ip" "ip" {
  count = "${var.lb["required"] ? 1 : 0}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name     = "${var.compute["name"]}-lb-ip"
  location = "${var.lb["location"]}"

  domain_name_label            = "${var.lb["domain_name_label"] != "" ? var.lb["domain_name_label"] : var.compute["name"]}"
  public_ip_address_allocation = "${var.lb["ip_address_allocation"]}"
}

resource "azurerm_lb" "lb" {
  count = "${var.lb["required"] ? 1 : 0}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name     = "${var.compute["name"]}-lb"
  location = "${var.lb["location"]}"

  frontend_ip_configuration {
    name = "${var.compute["name"]}-ip-config"

    public_ip_address_id = "${azurerm_public_ip.ip.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "lb_bepool" {
  count = "${var.lb["required"] ? 1 : 0}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name            = "${var.compute["name"]}-bepool"
  loadbalancer_id = "${join("", azurerm_lb.lb.*.id)}"
}

resource "azurerm_lb_probe" "lb_probes" {
  count = "${var.lb["required"] ? length(var.lb_probes) : 0}"

  resource_group_name = "${var.compute["resource_group_name"]}"
  loadbalancer_id     = "${azurerm_lb.lb.id}"

  name         = "${lookup(var.lb_probes[count.index], "name")}"
  protocol     = "${lookup(var.lb_probes[count.index], "protocol", "Tcp")}"
  port         = "${lookup(var.lb_probes[count.index], "port")}"
  request_path = "${lookup(var.lb_probes[count.index], "request_path", "")}"

  interval_in_seconds = "${lookup(var.lb_probes[count.index], "interval_in_seconds", "15")}"
  number_of_probes    = "${lookup(var.lb_probes[count.index], "number_of_probes", "2")}"
}

resource "azurerm_lb_rule" "lb_rules" {
  count = "${var.lb["required"] ? length(var.lb_rules) : 0}"

  resource_group_name            = "${var.compute["resource_group_name"]}"
  loadbalancer_id                = "${azurerm_lb.lb.id}"
  frontend_ip_configuration_name = "${lookup(azurerm_lb.lb.frontend_ip_configuration[0], "name")}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.lb_bepool.id}"

  probe_id = "${element(azurerm_lb_probe.lb_probes.*.id, lookup(var.lb_rules[count.index], "probe_index", 0))}"

  name          = "${lookup(var.lb_rules[count.index], "name")}"
  protocol      = "${lookup(var.lb_rules[count.index], "protocol", "Tcp")}"
  frontend_port = "${lookup(var.lb_rules[count.index], "frontend_port")}"
  backend_port  = "${lookup(var.lb_rules[count.index], "backend_port")}"

  idle_timeout_in_minutes = "${lookup(var.lb_rules[count.index], "idle_timeout_in_minutes", "4")}"
  load_distribution       = "${lookup(var.lb_rules[count.index], "load_distribution", "Default")}"
}

# ilb
data "azurerm_subnet" "ilb_subnet" {
  count = "${var.ilb["required"] ? 1 : 0}"

  resource_group_name  = "${var.ilb["vnet_resource_group_name"]}"
  virtual_network_name = "${var.ilb["vnet_name"]}"
  name                 = "${var.ilb["vnet_subnet_name"]}"
}

resource "azurerm_lb" "ilb" {
  count = "${var.ilb["required"] ? 1 : 0}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name     = "${var.compute["name"]}-ilb"
  location = "${var.ilb["location"]}"

  frontend_ip_configuration {
    name = "${var.compute["name"]}-ip-config"

    private_ip_address_allocation = "${var.ilb["private_ip_address"] != "" ? "Static" : "Dynamic"}"
    private_ip_address            = "${var.ilb["private_ip_address"]}"
    subnet_id                     = "${data.azurerm_subnet.ilb_subnet.id}"
  }
}

resource "azurerm_lb_backend_address_pool" "ilb_bepool" {
  count = "${var.ilb["required"] ? 1 : 0}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name            = "${var.compute["name"]}-bepool"
  loadbalancer_id = "${join("", azurerm_lb.ilb.*.id)}"
}

resource "azurerm_lb_probe" "ilb_probes" {
  count = "${var.ilb["required"] ? length(var.ilb_probes) : 0}"

  resource_group_name = "${var.compute["resource_group_name"]}"
  loadbalancer_id     = "${azurerm_lb.ilb.id}"

  name         = "${lookup(var.ilb_probes[count.index], "name")}"
  protocol     = "${lookup(var.ilb_probes[count.index], "protocol", "Tcp")}"
  port         = "${lookup(var.ilb_probes[count.index], "port")}"
  request_path = "${lookup(var.ilb_probes[count.index], "request_path", "")}"

  interval_in_seconds = "${lookup(var.ilb_probes[count.index], "interval_in_seconds", "15")}"
  number_of_probes    = "${lookup(var.ilb_probes[count.index], "number_of_probes", "2")}"
}

resource "azurerm_lb_rule" "ilb_rules" {
  count = "${var.ilb["required"] ? length(var.ilb_rules) : 0}"

  resource_group_name            = "${var.compute["resource_group_name"]}"
  loadbalancer_id                = "${azurerm_lb.ilb.id}"
  frontend_ip_configuration_name = "${lookup(azurerm_lb.ilb.frontend_ip_configuration[0], "name")}"
  backend_address_pool_id        = "${azurerm_lb_backend_address_pool.ilb_bepool.id}"

  probe_id = "${element(azurerm_lb_probe.ilb_probes.*.id, lookup(var.ilb_rules[count.index], "probe_index", 0))}"

  name          = "${lookup(var.ilb_rules[count.index], "name")}"
  protocol      = "${lookup(var.ilb_rules[count.index], "protocol", "Tcp")}"
  frontend_port = "${lookup(var.ilb_rules[count.index], "frontend_port")}"
  backend_port  = "${lookup(var.ilb_rules[count.index], "backend_port")}"

  idle_timeout_in_minutes = "${lookup(var.ilb_rules[count.index], "idle_timeout_in_minutes", "4")}"
  load_distribution       = "${lookup(var.ilb_rules[count.index], "load_distribution", "Default")}"
}

# virtual_machine
locals {
  vm_name_format = "${var.compute["name"]}-%02d"
  avset_required = "${var.lb["required"] || var.ilb["required"] || var.avset["required"]}"
}

data "azurerm_subnet" "subnet" {
  resource_group_name  = "${var.subnet["vnet_resource_group_name"]}"
  virtual_network_name = "${var.subnet["vnet_name"]}"
  name                 = "${var.subnet["name"]}"
}

data "azurerm_storage_account" "storage_account" {
  count = "${var.compute["boot_diagnostics_enabled"] ? 1 : 0}"

  resource_group_name = "${var.storage_account["resource_group_name"]}"
  name                = "${var.storage_account["name"]}"
}

data "azurerm_snapshot" "snapshot" {
  count = "${var.snapshot["name"] != "" ? 1 : 0}"

  resource_group_name = "${var.snapshot["resource_group_name"]}"
  name                = "${var.snapshot["name"]}"
}

resource "azurerm_virtual_machine" "vms" {
  count = "${length(var.computes)}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name     = "${lookup(var.computes[count.index], "computer_name", format(local.vm_name_format, count.index + 1))}"
  location = "${lookup(var.computes[count.index], "location", var.compute["location"])}"
  vm_size  = "${lookup(var.computes[count.index], "vm_size", var.compute["vm_size"])}"

  storage_os_disk {
    name = "${lookup(var.computes[count.index], "name", format(local.vm_name_format, count.index + 1))}-os-disk"

    os_type         = "${var.compute["os_type"]}"
    caching         = "ReadWrite"
    create_option   = "Attach"
    managed_disk_id = "${element(azurerm_managed_disk.os_disks.*.id, count.index)}"
  }

  delete_os_disk_on_termination = "${lookup(var.computes[count.index], "os_disk_on_termination", var.compute["os_disk_on_termination"])}"

  network_interface_ids = ["${element(azurerm_network_interface.nics.*.id, count.index)}"]
  availability_set_id   = "${local.avset_required ? "${join("", azurerm_availability_set.avset.*.id)}" : ""}"

  boot_diagnostics {
    enabled     = "${var.compute["boot_diagnostics_enabled"] ? lookup(var.computes[count.index], "boot_diagnostics_enabled", var.compute["boot_diagnostics_enabled"]) : false}"
    storage_uri = "${data.azurerm_storage_account.storage_account.primary_blob_endpoint}"
  }

  depends_on = [
    "azurerm_network_interface.nics",
    "azurerm_availability_set.avset",
    "azurerm_managed_disk.os_disks",
  ]
}

resource "azurerm_managed_disk" "os_disks" {
  count = "${length(var.computes)}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name     = "${lookup(var.computes[count.index], "name", format(local.vm_name_format, count.index + 1))}-os-disk"
  location = "${lookup(var.computes[count.index], "location", var.compute["location"])}"

  os_type              = "${var.compute["os_type"]}"
  create_option        = "${var.snapshot["name"] != "" ? "Copy" : "Import"}"
  storage_account_type = "${lookup(var.computes[count.index], "os_disk_type", var.compute["os_disk_type"])}"
  disk_size_gb         = "${lookup(var.computes[count.index], "os_disk_size_gb", var.compute["os_disk_size_gb"])}"

  source_resource_id = "${var.snapshot["name"] != "" ? join("", data.azurerm_snapshot.snapshot.*.id) : ""}"
  source_uri         = "${var.snapshot["name"] != "" ? "" : var.snapshot["uri"]}"
}

resource "azurerm_network_interface" "nics" {
  count = "${length(var.computes)}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name     = "${lookup(var.computes[count.index], "name", format(local.vm_name_format, count.index + 1))}-nic"
  location = "${lookup(var.computes[count.index], "location", var.compute["location"])}"

  ip_configuration {
    name      = "${lookup(var.computes[count.index], "name", format(local.vm_name_format, count.index + 1))}-ip-config"
    subnet_id = "${data.azurerm_subnet.subnet.id}"

    private_ip_address_allocation = "${lookup(var.computes[count.index], "private_ip_address", "") != "" ? "static" : "dynamic"}"
    private_ip_address            = "${lookup(var.computes[count.index], "private_ip_address", "")}"

    load_balancer_backend_address_pools_ids = [
      "${azurerm_lb_backend_address_pool.lb_bepool.*.id}",
      "${azurerm_lb_backend_address_pool.ilb_bepool.*.id}",
    ]
  }
}

# avset
resource "azurerm_availability_set" "avset" {
  count = "${local.avset_required ? 1 : 0}"

  resource_group_name = "${var.compute["resource_group_name"]}"

  name     = "${var.avset["name"] != "" ? var.avset["name"] : "${var.compute["name"]}-avset"}"
  location = "${var.avset["location"]}"

  platform_fault_domain_count  = "${var.avset["platform_fault_domain_count"]}"
  platform_update_domain_count = "${var.avset["platform_update_domain_count"]}"

  managed = "${var.avset["managed"]}"
}

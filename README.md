# vagrant-compose

A Vagrant plugin that helps building complex multi-machine scenarios.

Complex multi-machine scenarios includes several set of nodes, each one with different characteristic, software stacks and configuration. 

For instance, if you are setting up an environment for testing [Consul](https://consul.io/), your cluster will be composed by:

- consul server nodes
- consul agent nodes
- nodes simulating other datacenter
- ...

On top of that, a Consul cluster can be composed in several different ways, implementing high availability or not, merging roles/functions on the same server or keeping role/function separated etc. etc.

Vagrant-compose streamline the definition of complex multi-machine scenarios, providing also support for a straight forward provisioning of nodes with Ansible.

> So far, the plugin is designed for working with Ansible provisioning, but it can be easily used/extended for supporting other provisioning systems supported by Vagrant.

## Installation

Install the plugin following the typical Vagrant procedure:

``` 
$ vagrant plugin install vagrant-compose
```

## Quick start

Create the following `Vagrantfile` for implementing a multi-machine scenario that defines a cluster named `test` with 3 `consul-server` nodes.

``` ruby
Vagrant.configure(2) do |config|
  #cluster definition
  config.cluster.compose('test') do |c|
    c.nodes(3, 'consul-server')
  end

  #cluster creation
  config.cluster.nodes.each do |node, index|
    config.vm.define "#{node.boxname}" do |node_vm|
      node_vm.vm.box = "#{node.box}"
    end
  end
end
```

The first part of the `Vagrantfile` contains the definition of the `test` cluster:  

``` ruby
config.cluster.compose('test') do |c|
  ...    
end
```

Please note that the cluster definition, is followed by a block of code that allows to configure the cluster itself; in this example the configuration consists in defining a set of 3 `consul-server` nodes.

``` ruby
c.nodes(3, 'consul-server')
```

When the definition of the cluster is completed, behind the scene vagrant-compose take care of  composing the cluster, and the resulting list of nodes will be available in the `config.cluster.nodes` variable.

The second part of the `Vagrantfile` creates the cluster by defining a vm in VirtualBox for each node in the cluster:

``` ruby
config.cluster.nodes.each do |node, index|
  config.vm.define "#{node.boxname}" do |node_vm|
    node_vm.vm.box = "#{node.box}"
  end
end
```

If you run `vagrant up` you will get a 3 node cluster with following machines, based on `ubuntu/trusty64` base box (default).

- `test-consul-server1`
- `test-consul-server2`
- `test-consul-server3`

Done !

Of course, real-word scenarios are more complex; it is necessary to get more control in configuring the cluster topology and machine attributes, and finally you need also to implement automatic provisioning of software stack installed in the machines. 

See following chapters for more details.

## Configuring the cluster

There are several options to customise the cluster definition.

### Defining cluster attributes

Cluster attributes apply to all the node in the cluster.

You can set set cluster attributes in the block of code that is passed as a second parameter to the `cluster.compose` method, as show in the following example:

``` ruby
config.cluster.compose('test') do |c|
  c.box = "centos/7"    
  ...	
end
```

Following cluster attributes are available:

- **box**, [String], default = 'ubuntu/trusty64'
  
  Sets the base box for nodes, a.k.a the image that will be used to spin up the machine; please note that the base box can be customised also for each set of nodes (see Defining set of nodes).


- **domain**, [String], default = 'vagrant'
  
  Sets the domain used for computing the nodes in the cluster; if the `domain` value is set to `nil` or `““` (empty string), the fully qualified name and the hostname of each nodes will be the same. 

### Defining set of nodes

A cluster can be composed by one or more set of nodes.

Each set of nodes represent a group of one or more nodes with similar characteristics. For instance, in a cluster defined for testing [Consul](https://consul.io/), you will get at least two set of nodes:

- Consul server nodes
- Consul agent nodes

Set of nodes can be defined in the block of code that is passed as a second parameter to the `cluster.compose` method, by using the `nodes` method as show in the following example:

``` ruby
config.cluster.compose('test') do |c|
  ...
  c.nodes(3, 'zookeeper')
  ...	
end
```

The first parameter of the `nodes` method is the number of nodes in the set, while the second parameter is the name of the set; `nodes` accepts an optional third parameter, allowing to define a block of code where it is possible to customise several attributes of the set of nodes itself: 

``` ruby
config.cluster.compose('test') do |c|
  ...
  c.nodes(3, 'zookeeper') do |n|
    n.box = "centos/7"
  end      
  ...	
end
```

Please note that all the available attributes can be set to:

- A literal value, like for instance `"centos/7". This value will be inherited - without changes - by all nodes in the set.
  
- A block of code, afterwards value_generator, that will be executed when building the nodes in the set. When calling the block of code, three parameters will be given:
  
  - **group_index**, [integer (zero based)], uniquely assigned to each set of nodes
  - **group_name**, [String], with the name of the set of nodes
  - **node_index**, [integer (zero based)], uniquely assigned to each node in the set
  
  An example of value_generator is the following lambda expression, that computes the host-name for each node in the cluster (`test-consul-server1`, `test-consul-server2`, etc. etc.):
  
  ``` ruby
  lambda { |group_index, group_name, node_index| 
    return "#{group_name}#{node_index + 1}" 
  }
  ```
  
  ​

Following set of nodes attributes are available:

- **box**, [String|String_Generator], default = `cluster.box`
  
  Sets the base box used for creating nodes in this set. 
  
- **boxname**, [String|String_Generator], default = `"#{group_name}#{node_index + 1}"`
  
  Sets the box name (a.k.a. the name of the machine in VirtualBox/VMware)  for each node in this set.
  
  Note: when generating nodes, the resulting boxname will be automatically prefixed by `"#{cluster_name}-"`.
  
- **hostname**, [String|String_Generator], default = `"#{group_name}#{node_index + 1}"`
  
  Sets the hostname for each node in this set. 
  
  Note: when generating nodes, the resulting hostname will be automatically prefixed by `"#{cluster_name}-"`; additionally the **fqdn** attribute will be computed by concatenating `".#{cluster.domain}"`, if defined (if `domain` is not defined, fqdn will be the same of hostname).


- **aliases**, [Array(String)|Array(String)_Generator], default = `[]`
  
  Allows to provide aliases for each node in this set. 
  
  Note: when generating nodes, aliases will be automatically concatenated into a string, comma separated.


- **ip**, [String|String_Generator], default = `"172.31.#{group_index}.#{100 + node_index + 1}"`
  
  Sets the ip for for each node in this set. 


- **cpus**, [Integer|Integer_Generator], default = `1`
  
  Sets the number of cpus for each node in this set. 


- **memory**, [Integer|Integer_Generator], default = `256` (MB)
  
  Sets the memory allocated for each node in this set. 


- **attributes**, [Hash(String, obj)|Hash(String, obj)_Generator], default = `{}`
  
  Allows to provide customisable additional attributes for each node in this set. 

> Please note that some attribute, like boxname, hostname, ip, *must* be different for each node in the set (and in the cluster).
> 
> Use value_generators for those attributes.

### Composing nodes

By executing the code blocks provided to  `cluster.compose` method, and also inner code blocks provided to `nodes` calls, the vagrant-compose plugin can compose the cluster topology, as a sum of all the nodes generated by each set. 

The resulting list of nodes is stored in the `config.cluster.nodes` variable; each node has following attributes assigned using value/value generators:

- **box**
- **boxname**
- **hostname**
- **fqdn**


- **aliases**


- **ip**


- **cpus**


- **memory**


- **attributes**



Two additional attributes will be automatically set for each node:

- **index**, [integer (zero based)], uniquely assigned to each node in the cluster
- **group_index**, [integer (zero based)], uniquely assigned to each node in a set of nodes

## Creating nodes 

Given the list of nodes stored in the `config.cluster.nodes` variable, it is possible to create a multi-machine environment by iterating over the list: 

``` ruby
config.cluster.nodes.each do |node|
  ...
end
```

Within the cycle you can instruct vagrant to create machines based on attributes of the current node; for instance, you can define a VM in VirtualBox (default Vagrant provider);  the example uses the [vagrant-hostmanager](https://github.com/smdahlen/vagrant-hostmanager) plugin to set the hostname into the guest machine:

``` ruby
config.cluster.nodes.each do |node|
  config.vm.define "#{node.boxname}" do |node_vm|
    node_vm.vm.box = "#{node.box}"
    node_vm.vm.network :private_network, ip: "#{node.ip}"
    node_vm.vm.hostname = "#{node.fqdn}"
    node_vm.hostmanager.aliases = node.aliases unless node.aliases.empty?
    node_vm.vm.provision :hostmanager
    
    node_vm.vm.provider "virtualbox" do |vb|
      vb.name = "#{node.boxname}"  
      vb.memory = node.memory
      vb.cpus = node.cpus
    end            
  end
end
```

> In order to increase performance of node creation, you can leverage on support for linked clones introduced by Vagrant 1.8.1. Add the following line to the above script:
> 
> vb.linked_clone = true if Vagrant::VERSION =~ /^1.8/

Hostmanager requires following additional settings before the `config.cluster.nodes.each` command:

``` ruby
config.hostmanager.enabled = false          
config.hostmanager.manage_host = true       
config.hostmanager.include_offline = true  
```

## Configuring ansible provisioning

The vagrant-compose plugin provides support for a straight forward provisioning of nodes in the cluster implemented with Ansible.

### Defining ansible_groups

Each set of nodes, and therefore all the nodes within the set, can be assigned to one or more ansible_groups.

In the following example, `consul-agent` nodes will be part of `consul` and `docker` ansible_groups.

``` ruby
c.nodes(3, 'consul-agent') do |n|
  ...
    n.ansible_groups = ['consul', 'docker']
end  
```

This configuration is used by the  `cluster.compose` method in order to define an **inventory file** where nodes (hosts in ansible "") clustered in group; the resulting list of ansible_groups, each with its own list of host  is stored in the `config.cluster.ansible_groups` variable.

Ansible playbook will use groups for providing different software stack to different machines.

Please note that the possibility to assign a node to one or more groups introduces an high degree of flexibility; for instance, it is easy to change the topology of the cluster above for instance when it is required to implement an http load balancer based on consul service discovery:

``` ruby
c.nodes(3, 'consul-agent') do |n|
  ...
  n.ansible_groups = ['consul', 'docker', 'registrator']
end  
c.nodes(1, 'load-balancer') do |n|
  ...
    n.ansible_groups = ['consul', 'docker', 'consul-template', 'nginx']
end
```

As you can see, `consul` and `docker` ansible_groups now include both nodes from `consul-agent` and `load-balancer` node set; vice versa, other groups like `registrator`, `consul-template`, `nginx` contain node only from one of the two nodes set.

Ansible playbook can leverage on groups for providing machines with the required software stacks.

### Defining group vars

In Ansible, the inventory file is usually integrated with a set of variables containing settings that will influence playbooks behaviour for all the host in a group.

The vagrant-compose plugin allows you to define one or more group_vars generator for each ansible_groups; group_vars generators are code block that will be instantiated during `cluster.compose` with two input parameters:

- **context_vars** see below
- **nodes**, list of nodes in the ansible_group

Expected output type is `Hash(String, Obj)`.

For instance, when building a [Consul](https://consul.io/) cluster, all the `consul-server` nodes have to be configured with the same `bootstrap_expect` parameter, that must be set to the number of `consul-server` nodes in the cluster:

``` ruby
config.cluster.compose('test') do |c|
  ...
  c.ansible_group_vars['consul-server'] = lambda { |context, nodes| 
    return { 'consul_bootstrap_expect' => nodes.length } 
  }
  ...
end
```

Ansible group vars will be stored into yaml files saved into `{cluster.ansible_playbook_path}\group_vars` folder.

The variable  `cluster.ansible_playbook_path` defaults to the current directory  (the directory of the Vagrantfile)  +  `/provisioning`; this value can be changed like any other cluster attributes (see Defining cluster attributes).

### Defining host vars

While group vars will influence playbooks behaviour for all hosts in a group, in Ansible host vars will influence playbooks behaviour for a specific host.

The vagrant-compose plugin allows to define one or more host_vars generator for each ansible_groups;  host_vars generators are code block that will be instantiated during `cluster.compose` with two input parameters:

- **context_vars** see below
- **node**, one node in the ansible_group

Expected output type is `Hash(String, Obj)`.

For instance, when building a [Consul](https://consul.io/) cluster, all the `consul-server` nodes should be configured with the ip to which Consul will bind client interfaces:

``` ruby
config.cluster.compose('test') do |c|
  ...
  c.ansible_host_vars['consul-server'] = lambda { |context, node| 
    return { 'consul_client_ip' => node.ip } 
  }
  ...
end
```

Ansible host vars will be stored into yaml files saved into `{cluster.ansible_playbook_path}\host_vars` folder.

### Context vars

Group vars and host var generation by design can operate only with the set of information that comes with a groups of nodes or a single node.

However, sometimes, it is necessary to share some information across group of nodes, like for instance providing information about zookeeper nodes to mesos master nodes.

This can be achieved by setting one or more context_vars generator for each ansible_groups.

> Context_vars generator are always executed before group_vars and host_vars generators; the resulting context, is given in input to group_vars and host_vars generators.

For instance, when building a [Consul](https://consul.io/) cluster, all the `consul-agent` nodes should be configured with the ip - the list of ip - to be used when joining the cluster; such list can be generated from the list of nodes in the `consul-server` set of nodes, and stored in a context_vars:

``` ruby
config.cluster.compose('test') do |c|
  ...
  c.ansible_context_vars['consul-server'] = lambda { |context, nodes| 
    return { 'consul-serverIPs' => nodes.map { |n| n.ip }.to_a } 
  }
  ...
end
```

Then, you can use the above context var when generating group_vars for nodes in the `consul-agent` group.

``` ruby
config.cluster.compose('test') do |c|
  ...
  c.ansible_context_vars['consul-server'] = lambda { |context, nodes| 
    return { 'serverIPs' => nodes.map { |n| n.ip }.to_a } 
  }
  c.ansible_group_vars['consul-agent'] = lambda { |context, nodes| 
    return { 'consul_joins' => context['consul-serverIPs']  } 
  }
  ...
end
```

## Creating nodes (with provisioning) 

Given `config.cluster.ansible_groups` variable, generated group_vars and host_vars files, and of course an ansible playbook, it is possible to integrate provisioning into the node creation sequence.

NB. The example uses ansible parallel execution (all nodes are provisioned together in parallel after completing node creation).

``` ruby
config.cluster.nodes.each do |node|
  config.vm.define "#{node.boxname}" do |node_vm|
    ...
    if node.index == config.cluster.nodes.size - 1
      node_vm.vm.provision "ansible" do |ansible|
        ansible.limit = 'all' # enable parallel provisioning
        ansible.playbook = "provisioning/playbook.yml"
        ansible.groups = config.cluster.ansible_groups
      end
    end
  end
end


```


require "vagrant"

require_relative "util/cluster"

module VagrantPlugins
  module Compose

  	# Vagrant compose plugin definition class.
  	# This plugins allows easy configuration of a data structure that can be used as a recipe
  	# for setting up and provisioning a vagrant cluster composed by several machines with different
  	# roles.
    class Config < Vagrant.plugin("2", :config)

      # After executing compose, it returns the list of nodes in the cluster.
      attr_reader :nodes

      # After executing compose, it returns the ansible_groups configuration for provisioning nodes in the cluster.
      attr_reader :ansible_groups

  	  def initialize
    		@nodes = {}
    		@ansible_groups = {}
  	  end

  	  # Implements cluster creation, through the execution of the give code.
  	  def compose (name, &block)
  	    # create the cluster (the data structure representing the cluster)
  		  @cluster = Cluster.new(name)
    		begin
  			     # executes the cluster configuration code
          	block.call(@cluster)
  		  rescue Exception => e
  	      raise VagrantPlugins::Compose::Errors::ClusterInitializeError, :message => e.message, :cluster_name => name
  	    end
  	    # tranform cluster configuration into a list of nodes/ansible groups to be used for
  		  @nodes, @ansible_groups = @cluster.compose
   	  end

   	  # Implements a utility method that allows to check the list of nodes generated by compose.
   	  def debug
   	  	puts "==> cluster #{@cluster.name} with #{nodes.size} nodes"
   	  	@nodes.each do |node|
  		   puts "        #{node.boxname} accessible as #{node.fqdn} #{node.aliases} #{node.ip} => [#{node.box}, #{node.cpus} cpus, #{node.memory} memory]"
   	  	end
      	puts "    ansible_groups filtered by #{@cluster.multimachine_filter}" if not @cluster.multimachine_filter.empty?
   	  end
    end
  end
end

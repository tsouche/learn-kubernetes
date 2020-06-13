

===============================================================================
===============================================================================

APPENDIX 2 - Kubernetes Nodes

===============================================================================
===============================================================================


A node is a worker machine in Kubernetes. A node may be a VM or physical 
machine (we then speak of a 'bare metal deployment'), depending on the cluster. 
Each node contains the services necessary to run pods and is managed by the 
master components. The services on a node include:

    - the container runtime,
    - kubelet
    - kube-proxy.



===============
1 - Node Status
===============


A node’s status contains the following information:
    - Addresses
    - Conditions
    - Capacity and Allocatable
    - Info

Node status and other details about a node can be displayed using below 
command:

$ kubectl describe node <insert-node-name-here>


1.1 - Addresses
===============

The usage of these fields varies depending on your cloud provider or bare metal 
configuration.

    HostName:   The hostname as reported by the node’s kernel. Can be 
                overridden via the kubelet --hostname-override parameter.
    ExternalIP: Typically the IP address of the node that is externally 
                routable (available from outside the cluster).
    InternalIP: Typically the IP address of the node that is routable only 
                within the cluster.


1.2 - Conditions
================

The conditions field describes the status of all Running nodes. Examples of 
conditions include:

Node                Condition
Ready	            True if the node is healthy and ready to accept pods,
                    False if the node is not healthy and is not accepting pods, 
                    Unknown if the node controller has not heard from the node 
                      in the last node-monitor-grace-period (default is 40 
                      seconds)
MemoryPressure	    True if pressure exists on the node memory – that is, if 
                      the node memory is low; 
                    False otherwise
PIDPressure	        True if pressure exists on the processes – that is, if 
                      there are too many processes on the node; 
                    False otherwise
DiskPressure	    True if pressure exists on the disk size – that is, if 
                      the disk capacity is low; 
                    False otherwise
NetworkUnavailable	True if the network for the node is not correctly 
                      configured, 
                    False otherwise

The node condition is represented as a JSON object. For example, the following 
response describes a healthy node.

"conditions": [
  {
    "type": "Ready",
    "status": "True",
    "reason": "KubeletReady",
    "message": "kubelet is posting ready status",
    "lastHeartbeatTime": "2019-06-05T18:38:35Z",
    "lastTransitionTime": "2019-06-05T11:41:27Z"
  }
]


If the Status of the Ready condition remains Unknown or False for longer than 
the pod-eviction-timeout, an argument is passed to the kube-controller-manager 
and all the Pods on the node are scheduled for deletion by the Node Controller. 
The default eviction timeout duration is five minutes. In some cases when the 
node is unreachable, the apiserver is unable to communicate with the kubelet 
on the node. The decision to delete the pods cannot be communicated to the 
kubelet until communication with the apiserver is re-established. In the 
meantime, the pods that are scheduled for deletion may continue to run on the 
partitioned node.

In versions of Kubernetes prior to 1.5, the node controller would force delete 
these unreachable pods from the apiserver. However, in 1.5 and higher, the 
node controller does not force delete pods until it is confirmed that they 
have stopped running in the cluster. You can see the pods that might be 
running on an unreachable node as being in the Terminating or Unknown state. 
In cases where Kubernetes cannot deduce from the underlying infrastructure if 
a node has permanently left a cluster, the cluster administrator may need to 
delete the node object by hand. Deleting the node object from Kubernetes 
causes all the Pod objects running on the node to be deleted from the 
apiserver, and frees up their names.

In version 1.12, TaintNodesByCondition feature is promoted to beta, so node 
lifecycle controller automatically creates taints that represent conditions. 
Similarly the scheduler ignores conditions when considering a Node; instead it 
looks at the Node’s taints and a Pod’s tolerations.

Now users can choose between the old scheduling model and a new, more flexible 
scheduling model. A Pod that does not have any tolerations gets scheduled 
according to the old model. But a Pod that tolerates the taints of a particular 
Node can be scheduled on that Node.

    Caution: Enabling this feature creates a small delay between the time when 
      a condition is observed and when a taint is created. This delay is 
      usually less than one second, but it can increase the number of Pods 
      that are successfully scheduled but rejected by the kubelet.

      
1.3 - Capacity and Allocatable
==============================

Describes the resources available on the node: CPU, memory and the maximum 
number of pods that can be scheduled onto the node.

The fields in the capacity block indicate the total amount of resources that 
a Node has. The allocatable block indicates the amount of resources on a Node 
that is available to be consumed by normal Pods.

You may read more about capacity and allocatable resources while learning how 
to reserve compute resources on a Node.


1.4 - Info
==========

Describes general information about the node, such as kernel version, 
Kubernetes version (kubelet and kube-proxy version), Docker version (if used), 
and OS name. This information is gathered by Kubelet from the node.



==============
2 - Management
==============


Unlike pods and services, a node is not inherently created by Kubernetes: it 
is created externally by cloud providers like Google Compute Engine, or it 
exists in your pool of physical or virtual machines. So when Kubernetes 
creates a node, it creates an object that represents the node. After creation, 
Kubernetes checks whether the node is valid or not. For example, if you try to 
create a node from the following content:

{
  "kind": "Node",
  "apiVersion": "v1",
  "metadata": {
    "name": "10.240.79.157",
    "labels": {
      "name": "my-first-k8s-node"
    }
  }
}

Kubernetes creates a node object internally (the representation), and 
validates the node by health checking based on the metadata.name field. If 
the node is valid – that is, if all necessary services are running – it is 
eligible to run a pod. Otherwise, it is ignored for any cluster activity until 
it becomes valid.

    Note: Kubernetes keeps the object for the invalid node and keeps checking 
      to see whether it becomes valid. You must explicitly delete the Node 
      object to stop this process.

Currently, there are three components that interact with the Kubernetes node 
interface: node controller, kubelet, and kubectl.

2.1 - Node Controller
=====================

The node controller is a Kubernetes master component which manages various 
aspects of nodes.

The node controller has multiple roles in a node’s life.

    - The first is assigning a CIDR block to the node when it is registered (if 
      CIDR assignment is turned on).

    - The second is keeping the node controller’s internal list of nodes up to 
      date with the cloud provider’s list of available machines. When running 
      in a cloud environment, whenever a node is unhealthy, the node controller 
      asks the cloud provider if the VM for that node is still available. If 
      not, the node controller deletes the node from its list of nodes.

    - The third is monitoring the nodes’ health. The node controller is 
      responsible for updating the NodeReady condition of NodeStatus to 
      ConditionUnknown when a node becomes unreachable (i.e. the node 
      controller stops receiving heartbeats for some reason, e.g. due to the 
      node being down), and then later evicting all the pods from the node 
      (using graceful termination) if the node continues to be unreachable. 
      (The default timeouts are 40s to start reporting ConditionUnknown and 
      5m after that to start evicting pods.) The node controller checks the 
      state of each node every --node-monitor-period seconds.

2.1.1 - Heartbeats
==================

Heartbeats, sent by Kubernetes nodes, help determine the availability of a 
node. There are two forms of heartbeats: updates of NodeStatus and the Lease 
object. Each Node has an associated Lease object in the kube-node-lease 
namespace . Lease is a lightweight resource, which improves the performance of 
the node heartbeats as the cluster scales.

The kubelet is responsible for creating and updating the NodeStatus and a Lease 
object.

    - The kubelet updates the NodeStatus either when there is change in status, 
      or if there has been no update for a configured interval. The default 
      interval for NodeStatus updates is 5 minutes (much longer than the 40 
      second default timeout for unreachable nodes).
    - The kubelet creates and then updates its Lease object every 10 seconds 
      (the default update interval). Lease updates occur independently from the 
      NodeStatus updates.
    

2.1.2- Reliability
==================

In Kubernetes 1.4, we updated the logic of the node controller to better 
handle cases when a large number of nodes have problems with reaching the 
master (e.g. because the master has networking problem). Starting with 1.4, 
the node controller looks at the state of all nodes in the cluster when making 
a decision about pod eviction.

In most cases, node controller limits the eviction rate to --node-eviction-rate 
(default 0.1) per second, meaning it won’t evict pods from more than 1 node 
per 10 seconds.

The node eviction behavior changes when a node in a given availability zone 
becomes unhealthy. The node controller checks what percentage of nodes in the 
zone are unhealthy (NodeReady condition is ConditionUnknown or ConditionFalse) 
at the same time. If the fraction of unhealthy nodes is at least 
--unhealthy-zone-threshold (default 0.55) then the eviction rate is reduced: 
if the cluster is small (i.e. has less than or equal to 
--large-cluster-size-threshold nodes - default 50) then evictions are stopped, 
otherwise the eviction rate is reduced to --secondary-node-eviction-rate 
(default 0.01) per second. The reason these policies are implemented per 
availability zone is because one availability zone might become partitioned 
from the master while the others remain connected. If your cluster does not 
span multiple cloud provider availability zones, then there is only one 
availability zone (the whole cluster).

A key reason for spreading your nodes across availability zones is so that the 
workload can be shifted to healthy zones when one entire zone goes down. 
Therefore, if all nodes in a zone are unhealthy then node controller evicts at 
the normal rate --node-eviction-rate. The corner case is when all zones are 
completely unhealthy (i.e. there are no healthy nodes in the cluster). In such 
case, the node controller assumes that there’s some problem with master 
connectivity and stops all evictions until some connectivity is restored.

Starting in Kubernetes 1.6, the NodeController is also responsible for evicting 
pods that are running on nodes with NoExecute taints, when the pods do not 
tolerate the taints. Additionally, as an alpha feature that is disabled by 
default, the NodeController is responsible for adding taints corresponding 
to node problems like node unreachable or not ready. See this documentation 
for details about NoExecute taints and the alpha feature.

Starting in version 1.8, the node controller can be made responsible for 
creating taints that represent Node conditions. This is an alpha feature of 
version 1.8.

2.2 - Self-Registration of Nodes
================================

When the kubelet flag --register-node is true (the default), the kubelet will 
attempt to register itself with the API server. This is the preferred pattern, 
used by most distros.

For self-registration, the kubelet is started with the following options:

    --kubeconfig - Path to credentials to authenticate itself to the apiserver.
    --cloud-provider - How to talk to a cloud provider to read metadata about 
        itself.
    --register-node - Automatically register with the API server.
    --register-with-taints - Register the node with the given list of taints 
        (comma separated <key>=<value>:<effect>). No-op if register-node is 
        false.
    --node-ip - IP address of the node.
    --node-labels - Labels to add when registering the node in the cluster 
        (see label restrictions enforced by the NodeRestriction admission 
        plugin in 1.13+).
    --node-status-update-frequency - Specifies how often kubelet posts node 
        status to master.

When the Node authorization mode and NodeRestriction admission plugin are 
enabled, kubelets are only authorized to create/modify their own Node resource.


2.2.1 - Manual Node Administration
==================================

A cluster administrator can create and modify node objects.

If the administrator wishes to create node objects manually, set the kubelet 
flag --register-node=false.

The administrator can modify node resources (regardless of the setting of 
--register-node). Modifications include setting labels on the node and marking 
it unschedulable.

Labels on nodes can be used in conjunction with node selectors on pods to 
control scheduling, e.g. to constrain a pod to only be eligible to run on a 
subset of the nodes.

Marking a node as unschedulable prevents new pods from being scheduled to that 
node, but does not affect any existing pods on the node. This is useful as a 
preparatory step before a node reboot, etc. For example, to mark a node 
unschedulable, run this command:

$ kubectl cordon $NODENAME

    Note: Pods created by a DaemonSet controller bypass the Kubernetes 
        scheduler and do not respect the unschedulable attribute on a node. 
        This assumes that daemons belong on the machine even if it is being 
        drained of applications while it prepares for a reboot.


2.3 - Node capacity
===================

The capacity of the node (number of cpus and amount of memory) is part of the 
node object. Normally, nodes register themselves and report their capacity 
when creating the node object. If you are doing manual node administration, 
then you need to set node capacity when adding a node.

The Kubernetes scheduler ensures that there are enough resources for all the 
pods on a node. It checks that the sum of the requests of containers on the 
node is no greater than the node capacity. It includes all containers started 
by the kubelet, but not containers started directly by the container runtime 
nor any process running outside of the containers.

If you want to explicitly reserve resources for non-Pod processes, follow this 
tutorial to reserve resources for system daemons.


3 - Master-Node Communications
==============================


This document catalogs the communication paths between the master (really the 
apiserver) and the Kubernetes cluster. The intent is to allow users to 
customize their installation to harden the network configuration such that the 
cluster can be run on an untrusted network (or on fully public IPs on a cloud 
provider).


3.1 - Cluster to Master
=====================

All communication paths from the cluster to the master terminate at the apiserver (none of the other master components are designed to expose remote services). In a typical deployment, the apiserver is configured to listen for remote connections on a secure HTTPS port (443) with one or more forms of client authentication enabled. One or more forms of authorization should be enabled, especially if anonymous requests or service account tokens are allowed.

Nodes should be provisioned with the public root certificate for the cluster such that they can connect securely to the apiserver along with valid client credentials. For example, on a default GKE deployment, the client credentials provided to the kubelet are in the form of a client certificate. See kubelet TLS bootstrapping for automated provisioning of kubelet client certificates.

Pods that wish to connect to the apiserver can do so securely by leveraging a service account so that Kubernetes will automatically inject the public root certificate and a valid bearer token into the pod when it is instantiated. The kubernetes service (in all namespaces) is configured with a virtual IP address that is redirected (via kube-proxy) to the HTTPS endpoint on the apiserver.

The master components also communicate with the cluster apiserver over the secure port.

As a result, the default operating mode for connections from the cluster (nodes and pods running on the nodes) to the master is secured by default and can run over untrusted and/or public networks.


3.2 - Master to Cluster
=======================

There are two primary communication paths from the master (apiserver) to the cluster. The first is from the apiserver to the kubelet process which runs on each node in the cluster. The second is from the apiserver to any node, pod, or service through the apiserver’s proxy functionality.


3.2.1 - apiserver to kubelet
============================

The connections from the apiserver to the kubelet are used for:

    Fetching logs for pods.
    Attaching (through kubectl) to running pods.
    Providing the kubelet’s port-forwarding functionality.

These connections terminate at the kubelet’s HTTPS endpoint. By default, the apiserver does not verify the kubelet’s serving certificate, which makes the connection subject to man-in-the-middle attacks, and unsafe to run over untrusted and/or public networks.

To verify this connection, use the --kubelet-certificate-authority flag to provide the apiserver with a root certificate bundle to use to verify the kubelet’s serving certificate.

If that is not possible, use SSH tunneling between the apiserver and kubelet if required to avoid connecting over an untrusted or public network.

Finally, Kubelet authentication and/or authorization should be enabled to secure the kubelet API.


3.2.2 - apiserver to nodes, pods, and services
==============================================

The connections from the apiserver to a node, pod, or service default to plain HTTP connections and are therefore neither authenticated nor encrypted. They can be run over a secure HTTPS connection by prefixing https: to the node, pod, or service name in the API URL, but they will not validate the certificate provided by the HTTPS endpoint nor provide client credentials so while the connection will be encrypted, it will not provide any guarantees of integrity. These connections are not currently safe to run over untrusted and/or public networks.


3.2.3 - SSH Tunnels
===================

Kubernetes supports SSH tunnels to protect the Master -> Cluster communication paths. In this configuration, the apiserver initiates an SSH tunnel to each node in the cluster (connecting to the ssh server listening on port 22) and passes all traffic destined for a kubelet, node, pod, or service through the tunnel. This tunnel ensures that the traffic is not exposed outside of the network in which the nodes are running.

SSH tunnels are currently deprecated so you shouldn’t opt to use them unless you know what you are doing. A replacement for this communication channel is being designed.


4 - Controllers
===============


In robotics and automation, a control loop is a non-terminating loop that regulates the state of a system.

Here is one example of a control loop: a thermostat in a room.

When you set the temperature, that’s telling the thermostat about your desired state. The actual room temperature is the current state. The thermostat acts to bring the current state closer to the desired state, by turning equipment on or off.

In Kubernetes, controllers are control loops that watch the state of your cluster , then make or request changes where needed. Each controller tries to move the current cluster state closer to the desired state.


4.1 - Controller pattern
========================

A controller tracks at least one Kubernetes resource type. These objects have a spec field that represents the desired state. The controller(s) for that resource are responsible for making the current state come closer to that desired state.

The controller might carry the action out itself; more commonly, in Kubernetes, a controller will send messages to the API server that have useful side effects. You’ll see examples of this below.


4.1.1 - Control via API server
==============================

The Job controller is an example of a Kubernetes built-in controller. Built-in controllers manage state by interacting with the cluster API server.

Job is a Kubernetes resource that runs a Pod , or perhaps several Pods, to carry out a task and then stop.

(Once scheduled, Pod objects become part of the desired state for a kubelet).

When the Job controller sees a new task it makes sure that, somewhere in your cluster, the kubelets on a set of Nodes are running the right number of Pods to get the work done. The Job controller does not run any Pods or containers itself. Instead, the Job controller tells the API server to create or remove Pods. Other components in the control plane act on the new information (there are new Pods to schedule and run), and eventually the work is done.

After you create a new Job, the desired state is for that Job to be completed. The Job controller makes the current state for that Job be nearer to your desired state: creating Pods that do the work you wanted for that Job, so that the Job is closer to completion.

Controllers also update the objects that configure them. For example: once the work is done for a Job, the Job controller updates that Job object to mark it Finished.

(This is a bit like how some thermostats turn a light off to indicate that your room is now at the temperature you set).


4.1.2 - Direct control
======================

By contrast with Job, some controllers need to make changes to things outside of your cluster.

For example, if you use a control loop to make sure there are enough Nodes in your cluster, then that controller needs something outside the current cluster to set up new Nodes when needed.

Controllers that interact with external state find their desired state from the API server, then communicate directly with an external system to bring the current state closer in line.

(There actually is a controller that horizontally scales the nodes in your cluster. See Cluster autoscaling).


4.2 - Desired versus current state
==================================

Kubernetes takes a cloud-native view of systems, and is able to handle constant change.

Your cluster could be changing at any point as work happens and control loops automatically fix failures. This means that, potentially, your cluster never reaches a stable state.

As long as the controllers for your cluster are running and able to make useful changes, it doesn’t matter if the overall state is or is not stable.


4.3 - Design
============

As a tenet of its design, Kubernetes uses lots of controllers that each manage 
a particular aspect of cluster state. Most commonly, a particular control loop 
(controller) uses one kind of resource as its desired state, and has a 
different kind of resource that it manages to make that desired state happen.

It’s useful to have simple controllers rather than one, monolithic set of 
control loops that are interlinked. Controllers can fail, so Kubernetes is 
designed to allow for that.

For example: a controller for Jobs tracks Job objects (to discover new work) 
and Pod object (to run the Jobs, and then to see when the work is finished). 
In this case something else creates the Jobs, whereas the Job controller 
creates Pods.

    Note:

    There can be several controllers that create or update the same kind of 
    object. Behind the scenes, Kubernetes controllers make sure that they only 
    pay attention to the resources linked to their controlling resource.

    For example, you can have Deployments and Jobs; these both create Pods. The 
    Job controller does not delete the Pods that your Deployment created, 
    because there is information (labels) the controllers can use to tell those 
    Pods apart.


4.4 - Ways of running controllers
=================================

Kubernetes comes with a set of built-in controllers that run inside the kube-controller-manager . These built-in controllers provide important core behaviors.

The Deployment controller and Job controller are examples of controllers that come as part of Kubernetes itself (“built-in” controllers). Kubernetes lets you run a resilient control plane, so that if any of the built-in controllers were to fail, another part of the control plane will take over the work.

You can find controllers that run outside the control plane, to extend Kubernetes. Or, if you want, you can write a new controller yourself. You can run your own controller as a set of Pods, or externally to Kubernetes. What fits best will depend on what that particular controller does.






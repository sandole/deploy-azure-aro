# App location variable
$Dir = "$Home\Desktop\AppLocation\m04"

# ARO Cluster
$env:KUBECONFIG="kubeconfig_aro"

# Deploy nginx
./oc create deployment nginx --image=nginx

# Delete nginx
./oc delete deployment nginx

# Deploy in code
code $Dir\nginx.yaml
./oc apply -f $Dir\nginx.yaml
./oc get deployment,pods
./oc expose deployment nginx --port=80 --target-port=80 --type=LoadBalancer

$SERVICEIP=(./oc get service nginx -o jsonpath='{ .status.loadBalancer.ingress[0].ip }')
Start-Process http://$SERVICEIP

# OCP Cluster context
$env:KUBECONFIG="kubeconfig_ocp"
./oc apply -f $Dir\nginx.yaml

# Use node port service
./oc expose deployment nginx --target-port=80 --type=NodePort

# Save port
$PORT = (./oc get service nginx -o jsonpath='{.spec.ports[0].nodePort }')

# Start nodes on this port
Start-Process http://ocp-w-2.ocp.mycustomdomain.io:$PORT
Start-Process http://ocp-w-3.ocp.mycustomdomain.io:$PORT

# Example WordPress application
./oc new-project wordpress

Start-Process http://console-openshift-console.apps.ocp.mycustomdomain.io/
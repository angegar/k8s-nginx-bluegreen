# helm upgrade \
#    -f ./website/values.yaml \
#     --install \
#     --atomic \
#     --create-namespace \
#     --set productionSlot=blue \
#     --set blue.enabled=true \
#     website ./website/


# Get current namespace

if [ $(kubectl get pods -n blue --no-headers=true | wc -l) -eq 1 ];then
    newNamespace=green
    oldNamespace=blue
else
    newNamespace=blue
    oldNamespace=green
fi

echo "Deploy new version into the namespace $newNamespace"

helm upgrade \
   -f ./bluegreen/values.yaml \
    --install \
    --atomic \
    --create-namespace \
    --namespace $newNamespace \
    bluegreen ./bluegreen/

echo "Update ingresses to get a link to the new version $newNamespace"


helm upgrade \
   -f ./bluegreen-ing/values.yaml \
    --install \
    --atomic \
    --create-namespace \
    --namespace bluegreen-ing \
    --set productionBackend="bluegreen.$oldNamespace.svc.cluster.local" \
    --set stagingBackend="bluegreen.$newNamespace.svc.cluster.local" \
    bluegreen-ing ./bluegreen-ing/



read -rs -p 'Switch production ?'
echo "Switch the production to the new version in the namespace $newNamespace"
# sleep 30

helm upgrade \
   -f ./bluegreen-ing/values.yaml \
    --install \
    --atomic \
    --create-namespace \
    --namespace bluegreen-ing \
    --set productionBackend="bluegreen.$newNamespace.svc.cluster.local" \
    --set stagingBackend="bluegreen.$oldNamespace.svc.cluster.local" \
    bluegreen-ing ./bluegreen-ing/

echo "Delete the old version from the namespace $oldNamespace"
helm delete -n $oldNamespace bluegreen


# helm template \
#    -f ./bluegreen-ing/values.yaml \
#     --atomic \
#     --namespace bluegreen-ing \
#     --set productionBackend="bluegreen.$newNamespace" \
#     --set stagingBackend="bluegreen.$oldNamespace" \
#     bluegreen-ing ./bluegreen-ing/
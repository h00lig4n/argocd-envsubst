# argocd-envsubst
*Disclaimer*: I take no responsibility for offending GitOps purests.

This ArgoCD ConfigManagementPlugin has two functions:
1. Replacing environment variables in kubernetes yaml manifest files.
2. Reading in external manifest yaml files to be synchonized with an application.

It will run on ArgoCD Application sync.

## Configuration
This plugin will run on all yaml files (note I forgot to add .yml) in an ArgoCD Application as Discovery is used.
It will also search for a file called external_source.json.

### Variable Definition
It replaces environment variables in the form $VARIABLE or ${VARIABLE} with the value from the matching environment variable.
The following Ingress contains $DOMAIN_NAME, for example.
```
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: esphome
  namespace: hass
  annotations:
    traefik.ingress.kubernetes.io/router.middlewares: default-redirect-https@kubernetescrd
spec:
  ingressClassName: traefik
  rules:
    - host: esp.$DOMAIN_NAME
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: esphome
                port:
                  number: 6052
  tls:
    - secretName: tls-certificate
      hosts:
        - esp.$DOMAIN_NAME
```


These can be defined either:
1. On Application level by The Application definition in ArgoCD
```
apiVersion: argoproj.io/v1alpha1
kind: Application
spec:
  source:
    plugin:
      env:
        - name: DOMAIN_NAME
          value: secret.domain.com
```
2. They can be added directly to the sidecar environment variables when you patch the argocd-repo-server pod.
Refer to [patch.yaml](https://github.com/h00lig4n/argocd-envsubst/blob/main/patch.yaml).
```
env:
  - name: MY_EXAMPLE_VARIABLE
    value: my_example_variable_value
```

### external_sources.json
Sometimes your application uses an externally hosted yaml manifest. Perhaps there is no chart or you just don't like helm. 

1. Add a file called external_sources.json to the root of your repository.
2. Populate it with a json array of the manifest urls you want to sync.
**NOTE:**: When linking to a manifest in Github, you must use the RAW url, as shown in the example. It doesn't like HTML.
```
["https://raw.githubusercontent.com/h00lig4n/argocd-envsubst/refs/heads/main/patch.yaml","https://raw.githubusercontent.com/h00lig4n/k3s/refs/heads/main/esphome/deployment.yaml"]
```

## Installation
Refer to variable defintion above first. If you don't want global variables defined then just apply the patch as is.

Take a copy of the argocd-repo-server yaml first, just in case this goes wrong.
Then patch argocd-repo-server with the sidecar.
```
kubectl get deploy deploymentname -o yaml -n argocd
kubectl patch deployment argocd-repo-server -n argocd --patch-file=patch.yaml
```

### Troubleshooting
1. Check to see that your pod(s) are running: ```kubectl get pods -n argocd```
2. Make sure you can see both containers running or if there is error information: ```kubectl describe pod argocd-repo-server-xxxxxxx -n argocd```
3. Examine the logs in the containers for clues:
```
kubectl logs -l app.kubernetes.io/name=argocd-repo-server -c envsubst -n -n argocd
kubectl logs -l app.kubernetes.io/name=argocd-repo-server -c argocd-repo-server -n -n argocd
```
If the containers are running you can also see the error information in ArgoCD Web Interface.






# argocd-envsubst
*Disclaimer*: I take no responsibility for offending GitOps purists.

This ArgoCD ConfigManagementPlugin has two functions:
1. Replacing environment variables in kubernetes yaml manifest files.
2. Reading in external manifest yaml files to be synchonized with an application.



It will run on ArgoCD Application sync.

## Configuration

The [Container Image](https://hub.docker.com/repository/docker/h00lig4n/argocd-envsubst-plugin/general) is built for linux/amd64 and linux/arm64. 
It has only been tested on arm64.
This plugin will run on all yaml files (even yml).
It will run for all applications as ArgoCD Application as Discovery is used.
It will also search for a file called external_sources.json which should contain an array of URLs to remote yaml manifests.

### Variable Definition
It replaces environment variables in the form '$VARIABLE' or '${VARIABLE}' with the value from the matching environment variable.
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

Variables can be defined either:
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
Update [patch.yaml](https://github.com/h00lig4n/argocd-envsubst/blob/main/patch.yaml) with your own variables.
```
env:
  - name: DOMAIN_NAME
    value: secret.domain.com
```

### external_sources.json
Sometimes your application uses an externally hosted yaml manifest. Perhaps there is no chart available or you just don't like helm. 
This functionality will allow you to add references to those yaml files in order for them to be included in Sync.

1. Add a file called external_sources.json to the root of your repository.
2. Populate it with a json array of the manifest urls you want to sync. It expects a json array of strings, no parent object nor object array.
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







#################
# NEXUS TARGETS #
#################
nexusLogin:
	docker login $(NEXUS_HOST) -u "$(NEXUS_USERNAME)" -p "$(NEXUS_PASSWORD)"

################
# KUBE TARGETS #
################
applyArnConfig: cleanEnv .env
	docker-compose run --rm kubectl sh -c  "aws eks update-kubeconfig --name $(EKS_CLUSTER_NAME)"

istio.install: cleanEnv .env
	docker-compose run --rm kubectl ls /opt/istio
	#docker-compose run --rm kubectl cat /opt/istio/istio.VERSION
	docker-compose run --rm kubectl kubectl create namespace istio-system || echo "istio-system Namespace already created"
	docker-compose run --rm kubectl  sh -c 'helm template /opt/istio/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl apply -f -'

istio.deploy: cleanEnv .env
	docker-compose run --rm kubectl sh -c 'helm template /opt/istio/install/kubernetes/helm/istio --name istio --namespace istio-system \
	    --set global.proxy.accessLogFile="/dev/stdout" \
		--set global.configValidation=true \
		--set tracing.enabled=true \
		--set pilot.traceSampling=100 \
		--set kiali.enabled=true \
        --set "kiali.dashboard.jaegerURL=http://jaeger-query.istio-system:16686" \
        --set "kiali.dashboard.grafanaURL=http://grafana.istio-system:3000" \
		--set grafana.enabled=true \
		--set sidecarInjectorWebhook.enabled=true \
		--set servicegraph.enabled=true  | kubectl apply -f -'
	docker-compose run --rm kubectl sh -c "kubectl apply -f k8s-config/ingress.yml"
	docker-compose run --rm kubectl sh -c "envsubst < k8s-config/ingressgw-ssl.tmpl.json >  k8s-config/ingressgw-ssl.json"
	docker-compose run --rm kubectl sh -c 'mkdir -p  ingress-gw && aws secretsmanager get-secret-value --secret-id $(INGRESS_GW_CRT_ARN) | jq --raw-output '.SecretString' > ingress-gw/tls.crt && \
	aws secretsmanager get-secret-value --secret-id $(INGRESS_GW_KEY_ARN) | jq --raw-output '.SecretString' > ingress-gw/tls.key && \
	kubectl create -n istio-system secret tls $(INGRESS_GW_SSL_SECRET_NAME) --key ingress-gw/tls.key --cert ingress-gw/tls.crt || echo "Secret $(INGRESS_GW_SSL_SECRET_NAME) already created"'
	docker-compose run --rm kubectl sh -c 'kubectl -n istio-system patch --type=json deploy istio-ingressgateway -p "$$(cat k8s-config/ingressgw-ssl.json)" | echo "Already Patched"'


istio.gateway: cleanEnv .env
	docker-compose run --rm kubectl sh -c "envsubst < k8s-config/gateway.tmpl.yml >  k8s-config/gateway.yml"
	docker-compose run --rm kubectl sh -c "cat k8s-config/gateway.yml"
	docker-compose run --rm kubectl sh -c 'kubectl apply -f k8s-config/gateway.yml -n $(NAME_SPACE)'

istio.serviceEntry: cleanEnv .env
	docker-compose run --rm kubectl sh -c "cat k8s-config/serviceentry.yml"
	docker-compose run --rm kubectl sh -c 'kubectl apply -f k8s-config/serviceentry.yml -n $(NAME_SPACE)'

istio.envoyInjection: cleanEnv .env
	docker-compose run --rm kubectl sh -c 'kubectl label namespace $(NAME_SPACE) istio-injection=enabled || echo "Already Injected"'

# istio.policy: cleanEnv .env
# 	docker-compose run --rm kubectl sh -c "envsubst < k8s-config/istio-policy.tmpl.yml >  k8s-config/istio-policy.yml"
# 	docker-compose run --rm kubectl sh -c 'kubectl apply -f k8s-config/istio-policy.yml -n $(NAME_SPACE)'

istio.telemetry: cleanEnv .env
	docker-compose run --rm kubectl sh -c 'kubectl create secret generic kiali -n istio-system --from-literal=username=$(KIALI_USERNAME) --from-literal=passphrase=$(KIALI_PASSPHRASE) || echo "Secret Already Exsits"'
	docker-compose run --rm kubectl sh -c "envsubst < k8s-config/telemetry.tmpl.yml > k8s-config/telemetry.yml"
	docker-compose run --rm kubectl sh -c "cat k8s-config/telemetry.yml"
	docker-compose run --rm kubectl sh -c "kubectl apply -f k8s-config/telemetry.yml"
# istio.upgrade:
# 	docker-compose run --rm kubectl sh -c
# 	docker-compose run --rm kubectl sh -c 'helm template /opt/istio/install/kubernetes/helm/istio --name istio --namespace istio-system | kubectl apply -f -'

# istio.remove:
# 	docker-compose run --rm kubectl  sh -c 'helm template /opt/istio/install/kubernetes/helm/istio-init --name istio-init --namespace istio-system | kubectl delete -f -'

# istio.undeploy:
# 	docker-compose run --rm kubectl sh -c 'helm template /opt/istio/install/kubernetes/helm/istio --name istio --namespace istio-system  | kubectl delete -f -'
# 	docker-compose run --rm kubectl sh -c "kubectl delete -f k8s-config/ingress.yml"

################
# KUBE TARGETS # 
################
verify:
	docker-compose run --rm kubectl kubectl get svc -n istio-system
	docker-compose run --rm kubectl kubectl get pods -n istio-system

###########
# ENVFILE #
###########
.env:
	@echo "Create .env with .env.template"
# due to https://github.com/docker/compose/issues/6206 .env must exist before running anything with docker-compose
# we also ignore errors with '-' because "permission denied" probably means the file already exists, and disable output with '@'
	-@echo "" >> .env
# we must run cp in docker because Windows does not have cp
	docker-compose run --rm kubectl cp .env.template .env

cleanEnv:
	-@echo "" >> .env
	docker-compose run --rm kubectl rm -f .env

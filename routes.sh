sleep 20
http --ignore-stdin POST kong:8001/services/ name=api-service url=http://api-service/
http --ignore-stdin POST kong:8001/services/ name=desktop-service url=http://desktop-service/
http --ignore-stdin POST kong:8001/services/ name=desktop-service-ws url=http://desktop-service-ws/socket.io
http --ignore-stdin POST kong:8001/services/ name=account-service url=http://account-service/
http --ignore-stdin POST kong:8001/services/ name=cloud-service url=http://cloud-service/
http --ignore-stdin POST kong:8001/services/ name=cloud-provider-kubernetes url=http://cloud-provider-kubernetes/

http --ignore-stdin POST kong:8001/routes/ name=api-service-route service:='{"name":"api-service"}' paths:='["/api-service/"]'
http --ignore-stdin POST kong:8001/routes/ name=desktop-service-route service:='{"name":"desktop-service"}' paths:='["/desktop-service/"]'
http --ignore-stdin POST kong:8001/routes/ name=desktop-service-ws-route service:='{"name":"desktop-service-ws"}' paths:='["/desktop-service/ws"]'
http --ignore-stdin POST kong:8001/routes/ name=account-service-route service:='{"name":"account-service"}' paths:='["/account-service/"]'
http --ignore-stdin POST kong:8001/routes/ name=cloud-service-route service:='{"name":"cloud-service"}' paths:='["/cloud-service/"]'
http --ignore-stdin POST kong:8001/routes/ name=cloud-provider-kubernetes-route service:='{"name":"cloud-provider-kubernetes"}' paths:='["/cloud-provider-kubernetes/"]'

http --ignore-stdin POST kong:8001/upstreams/ name=api-service
http --ignore-stdin POST kong:8001/upstreams/ name=desktop-service
http --ignore-stdin POST kong:8001/upstreams/ name=desktop-service-ws
http --ignore-stdin POST kong:8001/upstreams/ name=account-service
http --ignore-stdin POST kong:8001/upstreams/ name=cloud-service
http --ignore-stdin POST kong:8001/upstreams/ name=cloud-provider-kubernetes

http --ignore-stdin POST kong:8001/upstreams/api-service/targets/ target=api-service:4020
http --ignore-stdin POST kong:8001/upstreams/desktop-service/targets/ target=desktop-service:4021
http --ignore-stdin POST kong:8001/upstreams/desktop-service-ws/targets/ target=desktop-service:4022
http --ignore-stdin POST kong:8001/upstreams/account-service/targets/ target=account-service:4011
http --ignore-stdin POST kong:8001/upstreams/cloud-service/targets/ target=cloud-service:4010
http --ignore-stdin POST kong:8001/upstreams/cloud-provider-kubernetes/targets/ target=cloud-provider-kubernetes:4000

http --ignore-stdin POST kong:8001/plugins/ name=request-transformer config.add.headers=Gateway-host:kong:8000 -f
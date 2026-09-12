# Cria o Plano do Servico de Aplicativo
az appservice plan create -n $PLANO -g $RG --is-linux --sku $SKU --location $LOCAL
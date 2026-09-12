# Cria o Servico de Aplicativo com runtime Java 21
az webapp create -g $RG --plan $PLANO -n $WEBAPP --runtime "JAVA:21-java21"
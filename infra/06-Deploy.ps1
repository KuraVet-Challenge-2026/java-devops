# Compila a aplicacao e publica o .jar no Web App.
.\mvnw.cmd clean package -DskipTests

az webapp deploy -g $RG -n $WEBAPP --src-path target\kuravet-0.0.1-SNAPSHOT.jar --type jar
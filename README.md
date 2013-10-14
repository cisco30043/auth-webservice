This repository provides a Java-based web service which returns DTCP authorization results as a JSON Web Signature in the compact serialization format.  Also provided are JSP pages which initiate the web service request via JavaScript, as well as a separate page which validates the web service results.

Relevant docs:
http://tools.ietf.org/html/draft-ietf-oauth-json-web-token-12
http://tools.ietf.org/html/draft-ietf-jose-json-web-signature-17
http://tools.ietf.org/html/draft-dthakore-tls-authz-04

Build dependencies:
 - git
 - maven2

Application and library dependencies:
 - Java 7 JDK (required by Tomcat 8)
 - OpenSSL with support for TLS extensions and supplemental data (https://community.cablelabs.com/wiki/display/CBLCVP2/Building+OpenSSL+with+TLS+authorization+extensions)
 - Apache 2 Web Server with support for TLS extensions and supplemental data (https://community.cablelabs.com/wiki/display/CBLCVP2/Building+Apache+with+mod_ssl+and+mod_dtcpip_auth)
 - DTCP auth Apache module (also https://community.cablelabs.com/wiki/display/CBLCVP2/Building+Apache+with+mod_ssl+and+mod_dtcpip_auth)
 - Apache Tomcat 8 and the mod_jk Apache module (http://tomcat.apache.org)
 - nimbus-jose-jwt library (https://bitbucket.org/nimbusds/nimbus-jose-jwt/wiki/Home) - provides JSON Web Signature support

Configuration files for Apache 2 as well as Tomcat 8 are provided.  The configuration files allow Apache to accept requests and forward requests to Tomcat for processing.  The configuration files also enable CORS (cross-origin resource sharing), allowing the authentication web service to run on a separate host from the host serving web content.

When a client application supporting DTCP TLS authorization requests the web page which initiates the web service authorization request, the results will look like this:

DTCP validation results: 
Originating server-provided ID: 156140
Auth server-provided ID: f45ad2d1-e225-47eb-b4c6-86550457bf32
Auth server name: server1
Issue date: Sun Oct 13 13:21:58 MDT 2013
Client IP address: 10.253.161.58
Signature verified: true
Cert chain verified: true
DTCP authorized: true

When a client application which doesn't support DTCP TLS authorization requests the web page which initiates the web service authorizatino request, the results should be similar but DTCP authorized will return false (note: if server1 or server2 are not trusted, the web service request will not succeed and no results will be returned to the client).

DTCP validation results:
Originating server-provided ID: 98865422
Auth server-provided ID: 329622aa-737d-487b-a284-08f7cfe94e67
Auth server name: server1
Issue date: Mon Oct 14 12:48:28 MDT 2013
Client IP address: 10.253.161.59
Signature verified: true
Cert chain verified: true
DTCP authorized: false

INSTALLATION AND CONFIGURATION INSTRUCTIONS:
Follow the instructions for building and installing OpenSSL followed by Apache2 and the DTCP auth Apache module from links provided above.

Tomcat 8 requires Java 7 - see:
http://tomcat.apache.org/whichversion.html

Install Java7 JDK if necessary:
sudo apt-get install openjdk-7-jdk
sudo /usr/sbin/update-alternatives --config java
select the option for the java 7 jre

Download and extract Apache Tomcat 8.0.0 (8.0.0 RC3 in these instructions):
wget http://mirror.nexcess.net/apache/tomcat/tomcat-8/v8.0.0-RC3/bin/apache-tomcat-8.0.0-RC3.tar.gz
tar xvf apache-tomcat-8.0.0-RC3.tar.gz

Download and extract the Tomcat connector source:
wget http://psg.mtu.edu/pub/apache//tomcat/tomcat-connectors/jk/tomcat-connectors-1.2.37-src.tar.gz
tar xvf tomcat-connectors-1.2.37-src.tar.gz

Build and install the jk Apache module:
cd tomcat-connectors-1.2.37-src/native
./configure --with-apxs=/absolute/path/to/apache2/bin/apxs
make
cd apache-2.0
This command will install the jk Apache module and update /absolute/path/to/apache2/conf/httpd.conf by adding the 'LoadModule jk_module modules/mod_jk.so' directive
sudo /absolute/path/to/apache2/bin/apxs -i -a mod_jk.la

Configure Tomcat and Apache to use the jk Apache module:
cd apache-tomcat-8.0.0-RC3
create an /absolute/path/to/tomcat/conf/workers.properties file:
touch /absolute/path/to/tomcat/conf/workers.properties

Contents of /absolute/path/to/tomcat/conf/workers.properties:
(Modify the host and port parameter as necessary to match the machine/port on which the Tomcat worker is listening)
--------------
worker.list=ajp13

worker.ajp13.type=ajp13
worker.ajp13.host=localhost
worker.ajp13.port=8009
worker.ajp13.connection_pool_size=10
worker.ajp13.connection_pool_timeout=600
worker.ajp13.socket_keepalive=1
worker.ajp13.socket_timeout=300
--------------

Update /absolute/path/to/apache2/conf/extra/httpd-ssl.conf to specify the jk Apache module settings:
(NOTE: an example httpd.conf and httpd-ssl.conf supporting the jk Apache module and is included in the repository)

If demonstrating CORS on the same machine, use two VirtualHost sections with different host names:
Copy the entire _default_ VirtualHost section in httpd-ssl.conf and paste it twice, renaming one to server1 and one to server2
(Update servername and certificate file and key entries - to avoid host mismatch, the server1 and server2 certs need to have 'server1' and 'server2' as their common names, respectively)

Add the following OUTSIDE of any VirtualHost section:
--------------
<IfModule jk_module>
JkWorkersFile /absolute/path/to/tomcat/conf/workers.properties
JkLogFile /absolute/path/to/tomcat/logs/mod_jk.log
JkLogLevel info
JkLogStampFormat "[%a %b %d %H:%M:%S %Y]"
JkRequestLogFormat "%w %V %T"
</IfModule>
--------------

Add the folling INSIDE any VirtualHost section supporting SSL:
(Modify the JkMount parameter to match the Tomcat web application)
--------------
<IfModule jk_module>
JkMount /examples ajp13
JkMount /examples/* ajp13
JkEnvVar DTCP_VALIDATION_SUCCESSFUL undefined
</IfModule>
--------------

Start Apache and Tomcat and Verify DTCP authorization works:
start Tomcat:
/absolute/path/to/tomcat/bin/startup.sh
start Apache:
sudo /absolute/path/to/apache2/bin/apachectl start

If the 'examples' JkMount is defined as above, browsing to https://SERVERNAME/examples/ should display the Tomcat examples page if the jk Apache module and Tomcat connectors are configured correctly.

DTCP authorization can be validated by modifying the /absolute/path/to/tomcat/webapps/examples/jsp/snp/snoop.jsp file to display the result of DTCP authorization:
<br>
DTCP AUTH: <%= request.getAttribute("DTCP_VALIDATION_SUCCESSFUL") %>

Browsing to https://SERVERNAME/examples/jsp/snp/snoop.jsp in a regular browser should display:
DTCP_AUTH:0

Browsing to https://SERVERNAME/examples/jsp/snp/snoop.jsp in a DTCP-enabled browser should display:
DTCP_AUTH:1

The remaining instructions leverage the existing Tomcat 'examples' web application to demonstrate DTCP authorization.  If that isn't the case, modify references to the web application where necessary.

Web app configuration:

Enable CORS support:
Add to /absolute/path/to/tomcat/webapps/examples/WEB-INF/web.xml:
(NOTE: a version of the example webapp web.xml which has been updated to support CORS is included in the repository)
--------------
<filter>
 <filter-name>CorsFilter</filter-name>
 <filter-class>org.apache.catalina.filters.CorsFilter</filter-class>
</filter>
<filter-mapping>
 <filter-name>CorsFilter</filter-name>
 <url-pattern>/*</url-pattern>
</filter-mapping>
--------------

Web app dependencies:

Install git if necessary:
sudo apt-get install git

Install maven2 if necessary:
sudo apt-get install maven2

Clone and build nimbus-jose-jwt:
git clone https://bitbucket.org/nimbusds/nimbus-jose-jwt.git
cd nimbus-jose-jwt
mvn package

Retrieve nimbus-jose-jwt dependencies:
mvn dependency:copy-dependencies

Copy jars:
cp /absolute/path/to/nimbus-jose-jwt/target/nimbus-jose-jwt-2.20-SNAPSHOT.jar /absolute/path/to/tomcat/webapps/examples/WEB-INF/lib
cp /absolute/path/to/nimbus-jose-jwt/target/dependency/* /absolute/path/to/tomcat/webapps/examples/WEB-INF/lib

Update properties used in web service and JSPs.  Example values provided - update as necessary.
(NOTE: a version of the example webapp web.xml which has been updated to include DTCP support is included in the repository)
Add to the webapp node in /absolute/path/to/tomcat/webapps/examples/WEB-INF/web.xml
--------------
  <context-param>
      <param-name>dtcp-web-service-url</param-name>
      <param-value>https://server1/examples/dtcpwebservice/dtcpwebservice.jsp</param-value>
  </context-param>
  <context-param>
      <!--the results of calling the dtcp web service url will be appended to this entry in a call to window.location.href-->
      <param-name>dtcp-verify-redirect</param-name>
      <param-value>/examples/verifydtcpauth/verifydtcpauth.jsp?data=</param-value>
  </context-param>
  <context-param>
      <param-name>certificate-file</param-name>
      <param-value>/absolute/path/to/der-encoded/x509/server/cert/file</param-value>
  </context-param>
  <context-param>
      <param-name>private-key-password</param-name>
      <param-value>private key password</param-value>
  </context-param>
  <context-param>
      <param-name>private-key-file</param-name>
      <param-value>/absolute/path/to/der-encoded/password-protected/private/key/file</param-value>
  </context-param>
  <context-param>
      <param-name>truststore-file</param-name>
      <param-value>/usr/lib/jvm/java-7-openjdk-amd64/jre/lib/security/cacerts</param-value>
  </context-param>
  <context-param>
      <param-name>truststore-password</param-name>
      <param-value>truststore password</param-value>
  </context-param>
--------------

Copy dtcpwebservice, verifydtcpauth and checkdtcpauth directories to the web application source directory
(the checkdtcpauth directory includes jquery-1.10.2.js and the JSP page includes this script with a server-side include to avoid Qt WebKit issues with 304 response codes and caching for requests sent over HTTPS).

Add server1 and server2 (if using CORS and on the same machine) to the system trust store (which will also add them to the 'current' java trust store)
cd /usr/share/ca-certificates
sudo mkdir cablelabs
Copy the 'first' and 'second' server files if they are installed on the same box (server1 and server2 are separate certs to the same path)
sudo cp /absolute/path/to/PEM-encoded/x509/cert/file1name cablelabs
sudo cp /absolute/path/to/PEM-encoded/x509/cert/file2name cablelabs

Update the certificate store (should also be performed on any client machine needing to trust the certificates):

Run: sudo dpkg-reconfigure ca-certificates
Enable the newly-added certs and dismiss the dialog (space bar, arrows and tab key to navigate/select)

dpkg-reconfigure ca-certificates is a UI which will add selected certs to /etc/ca-certificates.conf and run update-ca-certificates, 
which symlinks newly-added certificates to /etc/ssl/certs and updates the default java keystore)

NOTE: firefox and Chrome use a separate NSS certificate store - the above instructions won't prevent Firefox or Chrome from warning about untrusted certificates.

Add server1 and server2 to /etc/hosts file or DNS if needed

WHEN THE SERVER IS RESTARTED:
- Mount the truecrypt volume containing the DTCP keys and library
- Run sudo /absolute/path/to/apache2/bin/apachectl start
- Run /absolute/path/to/tomcat/bin/startup.sh

To demonstrate DTCP authorization, Build Qt with QT WebKit DTCP support (https://community.cablelabs.com/wiki/display/CBLCVP2/Building+Qt+with+OpenSSL+TLS+authorization+extension+support) and install WebKit, using the built Qt libraries.

To display the results of the DTCP auth web service (and exercise CORS support), request the page:
https://server2/examples/checkdtcpauth/checkdtcpauth.jsp

To display the results of the DTCP auth web service without exercising CORS support, request the page:
https://server1/examples/checkdtcpauth/checkdtcpauth.jsp


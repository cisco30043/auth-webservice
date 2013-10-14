<%@ page import="java.security.interfaces.RSAPublicKey" %>
<%@ page import="com.nimbusds.jose.crypto.RSASSAVerifier" %>
<%@ page import="com.nimbusds.jwt.SignedJWT" %>
<%@ page import="com.nimbusds.jose.JOSEException" %>
<%@ page import="com.nimbusds.jose.util.Base64" %>
<%@ page import="java.util.List" %>
<%@ page import="java.security.cert.CertificateFactory" %>
<%@ page import="java.security.cert.X509Certificate" %>
<%@ page import="java.io.ByteArrayInputStream" %>
<%@ page import="java.security.PublicKey" %>
<%@ page import="java.security.cert.CertPath" %>
<%@ page import="java.security.cert.PKIXParameters" %>
<%@ page import="java.security.cert.CertPathValidator" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.io.FileInputStream" %>
<%@ page import="java.security.KeyStore" %>
<%@ page import="java.util.Date" %>
<%@ page import="com.nimbusds.jwt.ReadOnlyJWTClaimsSet" %>
<%@ page import="java.security.cert.CertPathValidatorException" %>
<%@ page import="java.text.ParseException" %>
<%@ page import="java.security.cert.CertificateException" %>
<%@ page import="java.security.KeyStoreException" %>
<%@ page import="java.security.NoSuchAlgorithmException" %>
<%@ page import="java.security.InvalidAlgorithmParameterException" %>
<html>
<b>DTCP validation results:</b>
<br>
<%
    boolean signatureVerified = false;
    boolean dtcpAuthorized = false;
    boolean certChainVerified = false;
    String serverProvidedId = null;
    String serverName = null;
    String ipAddress = null;
    String jwtid = null;
    Date issued = null;

    String data = request.getParameter("data");

    if (data != null) {
        try {
            SignedJWT signedJWT = SignedJWT.parse(data);
            ReadOnlyJWTClaimsSet jwtClaimsSet = signedJWT.getJWTClaimsSet();

            dtcpAuthorized = Boolean.valueOf(jwtClaimsSet.getCustomClaim("DTCP_AUTH").toString());
            //server-provided ID may not be present
            Object serverProvidedIdObject = jwtClaimsSet.getCustomClaim("SERVER_PROVIDED_ID");
            if (null != serverProvidedIdObject)
            {
                serverProvidedId = serverProvidedIdObject.toString();
            }
            ipAddress = jwtClaimsSet.getCustomClaim("IP_ADDRESS").toString();
            serverName = jwtClaimsSet.getCustomClaim("SERVER_NAME").toString();
            issued = jwtClaimsSet.getIssueTime();
            jwtid = jwtClaimsSet.getJWTID();
            List<Base64> certChain = signedJWT.getHeader().getX509CertChain();
    
            ByteArrayInputStream certStream = new ByteArrayInputStream(certChain.get(0).decode());
            CertificateFactory cf = CertificateFactory.getInstance("X.509");
            X509Certificate cert = (X509Certificate)cf.generateCertificate(certStream);
            certStream.close();
    
            //to verify against a trust store with an installed cert:
            String filename = application.getInitParameter("truststore-file");
            FileInputStream is = new FileInputStream(filename);
            KeyStore trustStore = KeyStore.getInstance(KeyStore.getDefaultType());
            String trustStorePassword = application.getInitParameter("truststore-password");
            trustStore.load(is, trustStorePassword.toCharArray());
    
            PKIXParameters params = new PKIXParameters(trustStore);
    
            //to verify against a specific root cert:
    //        RandomAccessFile certChainFile = new RandomAccessFile(application.getInitParameter("certificate-file"), "r");
    //        byte[] certChainData = new byte[(int)certChainFile.length()];
    //        certChainFile.readFully(certChainData);
    //        certChainFile.close();
    //        ByteArrayInputStream anchorStream = new ByteArrayInputStream(certChainData);
    //        X509Certificate anchor = (X509Certificate)cf.generateCertificate(anchorStream);
    //        anchorStream.close();
    //
    //        Set<TrustAnchor> anchors =  new HashSet<TrustAnchor>();
    //        anchors.add(new TrustAnchor(anchor, null));
    //        PKIXParameters params = new PKIXParameters(anchors);
    
            params.setRevocationEnabled(false);
        
            CertificateFactory certFactory = CertificateFactory.getInstance("X.509");
            CertPath certPath = certFactory.generateCertPath(Arrays.asList(cert));
        
            CertPathValidator certPathValidator = CertPathValidator.getInstance("PKIX");
            try {
                certPathValidator.validate(certPath, params);
                certChainVerified = true;
            } catch (CertPathValidatorException e) {
                //don't display error
            }
            
            PublicKey publicKey = cert.getPublicKey();
        
            if ("RSA".equals(publicKey.getAlgorithm()))
            {
                RSASSAVerifier verifier = new RSASSAVerifier((RSAPublicKey)publicKey);
                signatureVerified = signedJWT.verify(verifier);
            }
        } catch (ParseException e) {
            //don't display error
        }
        catch (CertificateException e) {
            //don't display error
        } 
        catch (KeyStoreException e) {
            //don't display error
        }
        catch (NoSuchAlgorithmException e) {
            //don't display error
        } 
        catch (InvalidAlgorithmParameterException e) {
            //don't display error
        }
        catch (JOSEException e) {
            //don't display error
        }
    }
%>

Originating server-provided ID: <%=serverProvidedId%><br>
Auth server-provided ID: <%=jwtid%><br>
Auth server name: <%=serverName%><br>
Issue date: <%=issued%><br>
Client IP address: <%=ipAddress%><br>
Signature verified: <%=signatureVerified%><br>
Cert chain verified: <%=certChainVerified%><br>
DTCP authorized: <%=dtcpAuthorized%><br>
</html>
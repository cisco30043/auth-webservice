<%--
 Copyright (C) 2013  Cable Television Laboratories, Inc.
 Contact: http://www.cablelabs.com/

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS
 IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL CABLELABS OR ITS CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
--%>
<%--Prevent whitespace from allowing forwards--%>
<%@ page trimDirectiveWhitespaces="true" %>
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
if (signatureVerified && certChainVerified && dtcpAuthorized) {
    pageContext.forward(application.getInitParameter("dtcp-verify-auth-success-url"));
} else {
    pageContext.forward(application.getInitParameter("dtcp-verify-auth-fail-url"));
}
%>


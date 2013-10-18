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
<%@ page contentType="text/html; charset=iso-8859-1" language="java"%>

<%@ page import="java.io.FileNotFoundException" %>
<%@ page import="java.io.RandomAccessFile"%>

<%@ page import="java.security.KeyFactory"%>
<%@ page import="java.security.interfaces.RSAPrivateKey"%>
<%@ page import="java.security.Key" %>
<%@ page import="java.security.spec.KeySpec" %>
<%@ page import="java.security.InvalidKeyException" %>
<%@ page import="java.security.InvalidAlgorithmParameterException" %>
<%@ page import="java.security.spec.InvalidKeySpecException" %>
<%@ page import="java.security.NoSuchAlgorithmException" %>

<%@ page import="java.util.LinkedList" %>
<%@ page import="java.util.List"%>
<%@ page import="java.util.UUID"%>
<%@ page import="java.util.Date"%>

<%@ page import="javax.crypto.EncryptedPrivateKeyInfo" %>
<%@ page import="javax.crypto.Cipher" %>
<%@ page import="javax.crypto.spec.PBEKeySpec" %>
<%@ page import="javax.crypto.SecretKeyFactory" %>
<%@ page import="javax.crypto.NoSuchPaddingException" %>

<%@ page import="com.nimbusds.jose.JWSAlgorithm"%>
<%@ page import="com.nimbusds.jose.JWSHeader"%>
<%@ page import="com.nimbusds.jose.JWSObject" %>
<%@ page import="com.nimbusds.jose.JWSSigner"%>
<%@ page import="com.nimbusds.jose.JOSEException"%>
<%@ page import="com.nimbusds.jose.crypto.RSASSASigner"%>
<%@ page import="com.nimbusds.jose.util.Base64" %>
<%@ page import="com.nimbusds.jwt.JWTClaimsSet"%>
<%@ page import="com.nimbusds.jwt.SignedJWT"%>

<%
    SignedJWT signedJWT = null;
    String output = null;
    try {
        //dtcp authorization result
        Object dtcp = request.getAttribute("DTCP_VALIDATION_SUCCESSFUL");

        //optional ID provided by the server initiating the request 
        String providedId = request.getParameter("SERVER_PROVIDED_ID");
    
        JWTClaimsSet jwtClaims = new JWTClaimsSet();
        
        jwtClaims.setIssueTime(new Date());
        
        //locally-generated ID
        jwtClaims.setJWTID(UUID.randomUUID().toString());

        jwtClaims.setCustomClaim("DTCP_AUTH", dtcp != null && dtcp.toString().trim().equals("1") ? "true" : "false");

        if (null != providedId) {
            jwtClaims.setCustomClaim("SERVER_PROVIDED_ID", providedId);
        }

        //additional information to provide about the request
        jwtClaims.setCustomClaim("IP_ADDRESS", request.getRemoteAddr());
        jwtClaims.setCustomClaim("SERVER_NAME", request.getServerName());

        JWSHeader header = new JWSHeader(JWSAlgorithm.RS512);
    
        //command to generate DER-encoded certificate chain from PEM encoded cert chain:
        //openssl x509 -inform PEM -outform DER -in ./server1.crt -out ./server1.der
        RandomAccessFile certChainFile = new RandomAccessFile(application.getInitParameter("certificate-file"), "r");
        byte[] certChainData = new byte[(int)certChainFile.length()];
        certChainFile.readFully(certChainData);
        certChainFile.close();
    
        //add the cert chain to the header
        List<Base64> x5c = new LinkedList<Base64>();
        x5c.add(Base64.encode(certChainData));
        header.setX509CertChain(x5c);
        
        //command to generate PKCS8 DER-encoded RSA private key with no password from PEM encoded private key:
        //openssl pkcs8 -topk8  -nocrypt -outform DER -in server1.key -out server1-pri.der

        //if RSA private key in DER format was generated with -nocrypt, use:
        //KeySpec privateKeySpec = new PKCS8EncodedKeySpec(privateKeyData);
        //and call keyFactory.generatePrivate(privateKeySpec);

        //if RSA private key in DER format was generated without -nocrypt, use:
        RandomAccessFile privateKeyFile = new RandomAccessFile(application.getInitParameter("private-key-file"), "r");
        byte[] privateKeyData = new byte[(int)privateKeyFile.length()];
        privateKeyFile.readFully(privateKeyData);
        privateKeyFile.close();

        EncryptedPrivateKeyInfo privateKeyInfo = new EncryptedPrivateKeyInfo(privateKeyData);
        String privateKeyAlgorithmName = privateKeyInfo.getAlgName();

        PBEKeySpec passwordBasedKeySpec = new PBEKeySpec(application.getInitParameter("private-key-password").toCharArray());
        Key passwordBasedKey = SecretKeyFactory.getInstance(privateKeyAlgorithmName).generateSecret(passwordBasedKeySpec);

        Cipher cipher = Cipher.getInstance(privateKeyAlgorithmName);
        cipher.init(Cipher.DECRYPT_MODE, passwordBasedKey, privateKeyInfo.getAlgParameters());

        KeySpec privateKeySpec = privateKeyInfo.getKeySpec(cipher);

        RSAPrivateKey privateKey = (RSAPrivateKey) KeyFactory.getInstance("RSA").generatePrivate(privateKeySpec);

        JWSSigner signer = new RSASSASigner(privateKey);

        signedJWT = new SignedJWT(header, jwtClaims);
        signedJWT.sign(signer);

        //to generate compact format, use:
        output = signedJWT.serialize();

        //to generate JWS JSON Serialization format, use:
//        JSONObject result = new JSONObject();
//
//        JSONObject signatures = new JSONObject();
//        signatures.put("protected", signedJWT.getHeader().toJSONObject());
//        signatures.put("signature", signedJWT.getSignature());
//
//        List<Object> signaturesArray = new ArrayList<Object>();
//        signaturesArray.add(signatures);
//
//        result.put("payload", signedJWT.getPayload().toJSONObject());
//        result.put("signatures", signaturesArray);
//
//        //successfully signed
//        output = result.toJSONString();
    } catch (FileNotFoundException e) {
        //don't display
    } catch (InvalidKeySpecException e) {
        //don't display
    } catch (NoSuchAlgorithmException e) {
        //don't display
    } catch (NoSuchPaddingException e) {
        //don't display
    } catch (InvalidKeyException e) {
        //don't display
    } catch (InvalidAlgorithmParameterException e) {
        //don't display
    } catch (JOSEException e) {
        //don't display
    }

    //failed, return error status code without details
    if (null == signedJWT || !(signedJWT.getState() == JWSObject.State.SIGNED)) {
        response.sendError(500);
    } else {
        out.println(output);
    }
%>

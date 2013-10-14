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
 PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
--%>
<%@ page import="java.util.Random"%>

<%
    //prevent caching of the request
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1
    response.setHeader("Pragma", "no-cache"); // HTTP 1.0
    response.setDateHeader("Expires", 0);

    //use a random number as an example server-provided identifier    
    Random randGenerator = new Random();
%>
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>DTCP auth jQuery demo</title>
<script><jsp:include page="jquery-1.10.2.js"/></script>
</head>
<body>
<script>
$.ajax({
    url:"<%=application.getInitParameter("dtcp-web-service-url")%>",
    cache:false,
    crossdomain:true,
    data: {"SERVER_PROVIDED_ID": <%=randGenerator.nextInt(100000000)%>}, 
    success:function(result) {
        window.location.href = "<%=application.getInitParameter("dtcp-verify-redirect")%>" + result;
    }
});
</script>

</body>
</html>


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


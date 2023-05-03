package org.uiuc;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.google.gson.Gson;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.parser.OpenAPIV3Parser;
import java.io.IOException;
import java.io.FileWriter;
import java.util.*;
import java.util.concurrent.atomic.AtomicReference;

import io.swagger.v3.oas.models.media.Schema;
import io.swagger.oas.inflector.examples.models.Example;
import io.swagger.oas.inflector.examples.ExampleBuilder;
import com.fasterxml.jackson.databind.module.SimpleModule;
import io.swagger.oas.inflector.processors.JsonNodeExampleSerializer;
import io.swagger.util.Json;
import org.uiuc.dto.swagger.Endpoints;
import org.uiuc.dto.swagger.Request;
import java.io.File;
import java.util.stream.Collectors;

import static java.util.Objects.nonNull;
import static org.uiuc.dto.swagger.Request.*;

public class Main {
  public static void main(String[] args) throws IOException {

    String path = args[0];
    String output = args[1];
    List<Endpoints> endpoints = new ArrayList<>();
    File file = new File(path);
    OpenAPI swagger = new OpenAPIV3Parser().read(path);
    Map<String, Schema> definitions = swagger.getComponents().getSchemas();
    Endpoints endpoint = new Endpoints();
    endpoint.setMicroservice(file.getName().split("\\.")[0]);
    String hostUrl = swagger.getServers().get(0).getUrl();
    if(hostUrl.charAt(hostUrl.length()-1) == '/'){
      hostUrl = hostUrl.substring(0, hostUrl.length()-1);
    }
    endpoint.setHost(hostUrl);
    Map<String, List<Request>> methodToRequestMap = new HashMap<>();
    swagger
        .getPaths()
        .forEach(
            (k, v) -> {
              if (v.getGet() != null) {
                Request request = new Request();
                AtomicReference<String> str = new AtomicReference<>(k);
                Map<String, Object> pathParamExample = new HashMap<>();
                if (v.getGet().getParameters() != null && v.getGet().getParameters().size() > 0) {
                  v.getGet()
                      .getParameters()
                      .forEach(
                          param -> {
                            if (param.getIn().equals("query")) {
                              if (str.get().contains("{") && !str.get().contains("?")) {
                                str.set(
                                    str.get()
                                        + "?"
                                        + param.getName()
                                        + "={"
                                        + param.getName()
                                        + "}");
                              }
                              else if (!str.get().contains("{")) {
                                str.set(
                                    str.get()
                                        + "?"
                                        + param.getName()
                                        + "={"
                                        + param.getName()
                                        + "}");
                              }
                              else {
                                str.set(
                                    str.get()
                                        + "&"
                                        + param.getName()
                                        + "={"
                                        + param.getName()
                                        + "}");
                              }
                            }
                            if(param.getIn().equals("path") && nonNull(param.getExample())){
                                pathParamExample.put(param.getName(), param.getExample());
                            }
                          });

                }
                request.setUrl(str.get());
                if(pathParamExample.keySet().size()>0){
                    request.setPathParamExample(mapToString(pathParamExample));
                }
                if (!methodToRequestMap.containsKey("GET")) {
                  List<Request> list = new ArrayList<>();
                  list.add(request);
                  methodToRequestMap.put("GET", list);
                } else {
                  methodToRequestMap.get("GET").add(request);
                }
              }
              if (v.getPut() != null) {
                Request request = new Request();
                AtomicReference<String> str = new AtomicReference<>(k);
                if (v.getPut().getRequestBody() != null
                    && v.getPut().getRequestBody().getContent().values().stream()
                        .findFirst()
                        .isPresent()) {
                  // bodyRef - To handle Body | bodyItemsRef - To handle formData
                  String bodyRef = v.getPut().getRequestBody().getContent().values().stream()
                          .findFirst()
                          .get()
                          .getSchema()
                          .get$ref();
                    Map<String, Schema> nonBodyParams = v.getPut().getRequestBody().getContent().values().stream()
                            .findFirst()
                            .get()
                            .getSchema()
                            .getProperties();
                  String bodyType = v.getPut().getRequestBody().getContent().values().stream()
                          .findFirst()
                          .get()
                          .getSchema()
                          .getType();
                  String bodyItemsRef = null;
                  String bodyItemsType = null;
                  if(nonNull(v.getPut().getRequestBody().getContent().values().stream().findFirst().get().getSchema().getItems())){
                      bodyItemsRef = v.getPut().getRequestBody().getContent().values().stream()
                              .findFirst()
                              .get()
                              .getSchema()
                              .getItems()
                              .get$ref();
                      bodyItemsType = v.getPut().getRequestBody().getContent().values().stream().findFirst().get().getSchema().getItems().getType();
                  }
                  if(nonNull(bodyRef)){
                    request.setBody(bodyRef);
                    String obj[] = bodyRef.split("/");
                    String finalObj = obj[obj.length - 1];
                    request.setExample(getExampleJson(definitions, finalObj, null));
                    request.setContentType(REQUEST_BODY_CONTENT_TYPE);
                  }
                  else if(nonNull(bodyItemsRef)){
                      String typeOfBodyParam = v.getPut().getRequestBody().getContent().values().stream().findFirst().get().getSchema().getType();
                      request.setBody(bodyItemsRef);
                      String obj[] = bodyItemsRef.split("/");
                      String finalObj = obj[obj.length - 1];
                      request.setExample(getExampleJson(definitions, finalObj, typeOfBodyParam));
                      request.setContentType(REQUEST_BODY_CONTENT_TYPE);
                  }
                  else if(nonNull(nonBodyParams) && !nonBodyParams.isEmpty()){
                    Map<String, Object> paramAndExample = nonBodyParams.values().stream()
                            .collect(Collectors.toMap(Schema::getName, param -> getExampleForFormData(param.getType())));
                    SimpleModule simpleModule = new SimpleModule().addSerializer(new JsonNodeExampleSerializer());
                    Json.mapper().registerModule(simpleModule);
                    request.setExample(Json.pretty(paramAndExample));
                    request.setContentType(FORM_DATA_CONTENT_TYPE);
                  }
                  else {
                      String example;
                      if(nonNull(bodyType)){
                          if(bodyType.equals("array") && nonNull(bodyItemsType)){
                              example = getArrayExampleForFormData(bodyItemsType);
                          }
                          else{
                              example = (String) getExampleForFormData(bodyType);
                          }
                          request.setExample(example);
                          request.setContentType(REQUEST_BODY_CONTENT_TYPE);
                      }
                  }
                }
                  //To add path param example
                  Map<String, Object> pathParamExample = new HashMap<>();
                  if (nonNull(v.getPut().getParameters()) && v.getPut().getParameters().size() > 0) {
                      v.getPut().getParameters().forEach(param -> {
                          if (param.getIn().equals("query")) {
                              if (str.get().contains("{") && !str.get().contains("?")) {
                                  str.set(
                                          str.get()
                                                  + "?"
                                                  + param.getName()
                                                  + "={"
                                                  + param.getName()
                                                  + "}");
                              }
                              else if (!str.get().contains("{")) {
                                  str.set(
                                          str.get()
                                                  + "?"
                                                  + param.getName()
                                                  + "={"
                                                  + param.getName()
                                                  + "}");
                              }
                              else {
                                  str.set(
                                          str.get()
                                                  + "&"
                                                  + param.getName()
                                                  + "={"
                                                  + param.getName()
                                                  + "}");
                              }
                          }
                          else if(param.getIn().equals("path") && nonNull(param.getExample())){
                              pathParamExample.put(param.getName(), param.getExample());
                          }
                      });
                      if(pathParamExample.keySet().size()>0){
                          request.setPathParamExample(mapToString(pathParamExample));
                      }
                  }
                  request.setUrl(str.get());
                  if (!methodToRequestMap.containsKey("PUT")) {
                      List<Request> list = new ArrayList<>();
                      list.add(request);
                      methodToRequestMap.put("PUT", list);
                  } else {
                      methodToRequestMap.get("PUT").add(request);
                  }
              }
              if (v.getPost() != null) {
                Request request = new Request();
                AtomicReference<String> str = new AtomicReference<>(k);
                if (v.getPost().getRequestBody() != null) {
                  String bodyRef =
                      v.getPost().getRequestBody().getContent().values().stream()
                          .findFirst()
                          .get()
                          .getSchema()
                          .get$ref();
                  Map<String, Schema> nonBodyParams = v.getPost().getRequestBody().getContent().values().stream()
                          .findFirst()
                          .get()
                          .getSchema()
                          .getProperties();
                    String bodyType = v.getPost().getRequestBody().getContent().values().stream()
                            .findFirst()
                            .get()
                            .getSchema()
                            .getType();
                    String bodyItemsRef = null;
                    String bodyItemsType = null;
                    if(nonNull(v.getPost().getRequestBody().getContent().values().stream().findFirst().get().getSchema().getItems())){
                        bodyItemsRef = v.getPost().getRequestBody().getContent().values().stream()
                                .findFirst()
                                .get()
                                .getSchema()
                                .getItems()
                                .get$ref();
                        bodyItemsType = v.getPost().getRequestBody().getContent().values().stream().findFirst().get().getSchema().getItems().getType();
                    }
                    if (nonNull(bodyRef)) {
                        request.setBody(bodyRef);
                        String obj[] = bodyRef.split("/");
                        String finalObj = obj[obj.length - 1];
                        request.setExample(getExampleJson(definitions, finalObj, null));
                        request.setContentType(REQUEST_BODY_CONTENT_TYPE);
                    }
                    else if(nonNull(bodyItemsRef)){
                        String typeOfBodyParam = v.getPost().getRequestBody().getContent().values().stream().findFirst().get().getSchema().getType();
                        request.setBody(bodyItemsRef);
                        String obj[] = bodyItemsRef.split("/");
                        String finalObj = obj[obj.length - 1];
                        request.setExample(getExampleJson(definitions, finalObj, typeOfBodyParam));
                        request.setContentType(REQUEST_BODY_CONTENT_TYPE);
                    }
                    // Get formData params
                    else if(nonNull(nonBodyParams) && !nonBodyParams.isEmpty()){
                        Map<String, Object> paramAndExample = nonBodyParams.values().stream()
                                .collect(Collectors.toMap(Schema::getName, param -> getExampleForFormData(param.getType())));
                        SimpleModule simpleModule = new SimpleModule().addSerializer(new JsonNodeExampleSerializer());
                        Json.mapper().registerModule(simpleModule);
                        request.setExample(Json.pretty(paramAndExample));
                        request.setContentType(FORM_DATA_CONTENT_TYPE);
                    }
                    // For body with primitive data types
                    else {
                        String example;
                        if(nonNull(bodyType)){
                            if(bodyType.equals("array") && nonNull(bodyItemsType)){
                                example = getArrayExampleForFormData(bodyItemsType);
                            }
                            else{
                                example = (String) getExampleForFormData(bodyType);
                            }
                            request.setExample(example);
                            request.setContentType(REQUEST_BODY_CONTENT_TYPE);
                        }
                    }
                }
                  //To add path param example
                  Map<String, Object> pathParamExample = new HashMap<>();
                  if (nonNull(v.getPost().getParameters()) && v.getPost().getParameters().size() > 0) {
                      v.getPost().getParameters().forEach(param -> {
                          if (param.getIn().equals("query")) {
                              if (str.get().contains("{") && !str.get().contains("?")) {
                                  str.set(
                                          str.get()
                                                  + "?"
                                                  + param.getName()
                                                  + "={"
                                                  + param.getName()
                                                  + "}");
                              }
                              else if (!str.get().contains("{")) {
                                  str.set(
                                          str.get()
                                                  + "?"
                                                  + param.getName()
                                                  + "={"
                                                  + param.getName()
                                                  + "}");
                              }
                              else {
                                  str.set(
                                          str.get()
                                                  + "&"
                                                  + param.getName()
                                                  + "={"
                                                  + param.getName()
                                                  + "}");
                              }
                          }
                          else if(param.getIn().equals("path") && nonNull(param.getExample())){
                              pathParamExample.put(param.getName(), param.getExample());
                          }
                      });
                      if(pathParamExample.keySet().size()>0){
                          request.setPathParamExample(mapToString(pathParamExample));
                      }
                  }
                  request.setUrl(str.get());
                if (!methodToRequestMap.containsKey("POST")) {
                  List<Request> list = new ArrayList<>();
                  list.add(request);
                  methodToRequestMap.put("POST", list);
                } else {
                  methodToRequestMap.get("POST").add(request);
                }
              }
              if (v.getDelete() != null) {
                  Request request = new Request();
                  AtomicReference<String> str = new AtomicReference<>(k);
                  Map<String, Object> pathParamExample = new HashMap<>();
                  if (v.getDelete().getParameters() != null && v.getDelete().getParameters().size() > 0) {
                      v.getDelete()
                              .getParameters()
                              .forEach(
                                      param -> {
                                          if (param.getIn().equals("query")) {
                                              if (str.get().contains("{") && !str.get().contains("?")) {
                                                  str.set(
                                                          str.get()
                                                                  + "?"
                                                                  + param.getName()
                                                                  + "={"
                                                                  + param.getName()
                                                                  + "}");
                                              } else if (!str.get().contains("{")) {
                                                  str.set(
                                                          str.get()
                                                                  + "?"
                                                                  + param.getName()
                                                                  + "={"
                                                                  + param.getName()
                                                                  + "}");
                                              } else {
                                                  str.set(
                                                          str.get()
                                                                  + "&"
                                                                  + param.getName()
                                                                  + "={"
                                                                  + param.getName()
                                                                  + "}");
                                              }
                                          }
                                          if (param.getIn().equals("path") && nonNull(param.getExample())) {
                                              pathParamExample.put(param.getName(), param.getExample());
                                          }
                                      });

                  }
                  request.setUrl(str.get());
                  if(pathParamExample.keySet().size()>0){
                      request.setPathParamExample(mapToString(pathParamExample));
                  }
                if (!methodToRequestMap.containsKey("DELETE")) {
                  List<Request> list = new ArrayList<>();
                  list.add(request);
                  methodToRequestMap.put("DELETE", list);
                } else {
                  methodToRequestMap.get("DELETE").add(request);
                }
              }
              if (v.getPatch() != null) {
                Request request = new Request();
                AtomicReference<String> str = new AtomicReference<>(k);
                if (v.getPatch().getRequestBody() != null) {
                  String bodyRef =
                      v.getPatch().getRequestBody().getContent().values().stream()
                          .findFirst()
                          .get()
                          .getSchema()
                          .get$ref();
                  Map<String, Schema> nonBodyParams = v.getPatch().getRequestBody().getContent().values().stream()
                          .findFirst()
                          .get()
                          .getSchema()
                          .getProperties();
                    String bodyType = v.getPatch().getRequestBody().getContent().values().stream()
                            .findFirst()
                            .get()
                            .getSchema()
                            .getType();
                    String bodyItemsRef = null;
                    String bodyItemsType = null;
                    if(nonNull(v.getPatch().getRequestBody().getContent().values().stream().findFirst().get().getSchema().getItems())){
                        bodyItemsRef = v.getPatch().getRequestBody().getContent().values().stream()
                                .findFirst()
                                .get()
                                .getSchema()
                                .getItems()
                                .get$ref();
                        bodyItemsType = v.getPatch().getRequestBody().getContent().values().stream().findFirst().get().getSchema().getItems().getType();
                    }
                  if(nonNull(bodyRef)){
                    request.setBody(bodyRef);
                    String obj[] = bodyRef.split("/");
                    String finalObj = obj[obj.length - 1];
                    request.setExample(getExampleJson(definitions, finalObj, null));
                    request.setContentType(REQUEST_BODY_CONTENT_TYPE);
                  }
                  else if(nonNull(bodyItemsRef)){
                      String typeOfBodyParam = v.getPost().getRequestBody().getContent().values().stream().findFirst().get().getSchema().getType();
                      request.setBody(bodyItemsRef);
                      String obj[] = bodyItemsRef.split("/");
                      String finalObj = obj[obj.length - 1];
                      request.setExample(getExampleJson(definitions, finalObj, typeOfBodyParam));
                      request.setContentType(REQUEST_BODY_CONTENT_TYPE);
                  }
                  else if(nonNull(nonBodyParams) && !nonBodyParams.isEmpty()){
                    Map<String, Object> paramAndExample = nonBodyParams.values().stream()
                            .collect(Collectors.toMap(Schema::getName, param -> getExampleForFormData(param.getType())));
                    SimpleModule simpleModule = new SimpleModule().addSerializer(new JsonNodeExampleSerializer());
                    Json.mapper().registerModule(simpleModule);
                    request.setExample(Json.pretty(paramAndExample));
                    request.setContentType(FORM_DATA_CONTENT_TYPE);
                  }
                  else {
                      String example;
                      if(nonNull(bodyType)){
                          if(bodyType.equals("array") && nonNull(bodyItemsType)){
                              example = getArrayExampleForFormData(bodyItemsType);
                          }
                          else{
                              example = (String) getExampleForFormData(bodyType);
                          }
                          request.setExample(example);
                          request.setContentType(REQUEST_BODY_CONTENT_TYPE);
                      }
                  }
                }
                  //To add path param example
                  Map<String, Object> pathParamExample = new HashMap<>();
                  if (nonNull(v.getPatch().getParameters()) && v.getPatch().getParameters().size() > 0) {
                      v.getPatch().getParameters().forEach(param -> {
                          if (param.getIn().equals("query")) {
                              if (str.get().contains("{") && !str.get().contains("?")) {
                                  str.set(
                                          str.get()
                                                  + "?"
                                                  + param.getName()
                                                  + "={"
                                                  + param.getName()
                                                  + "}");
                              }
                              else if (!str.get().contains("{")) {
                                  str.set(
                                          str.get()
                                                  + "?"
                                                  + param.getName()
                                                  + "={"
                                                  + param.getName()
                                                  + "}");
                              }
                              else {
                                  str.set(
                                          str.get()
                                                  + "&"
                                                  + param.getName()
                                                  + "={"
                                                  + param.getName()
                                                  + "}");
                              }
                          }
                          else if(param.getIn().equals("path") && nonNull(param.getExample())){
                              pathParamExample.put(param.getName(), param.getExample());
                          }
                      });
                      if(pathParamExample.keySet().size()>0){
                          request.setPathParamExample(mapToString(pathParamExample));
                      }
                  }
                  request.setUrl(str.get());
                if (!methodToRequestMap.containsKey("PATCH")) {
                  List<Request> list = new ArrayList<>();
                  list.add(request);
                  methodToRequestMap.put("PATCH", list);
                } else {
                  methodToRequestMap.get("PATCH").add(request);
                }
              }
            });
    endpoint.setMethodToRequestMap(methodToRequestMap);

    endpoints.add(endpoint);
    Gson gson = new Gson();
    System.out.println(gson.toJson(endpoints));
    FileWriter writer = new FileWriter(output + "/output.json");
    writer.write(gson.toJson(endpoints));
    writer.close();
  }

  private static String getExampleJson(Map<String, Schema> definitions, String pojo, String typeOfBodyParam) {
      String stringExample = "";
    Schema model = definitions.get(pojo);
    Example example = ExampleBuilder.fromSchema(model, definitions);
    SimpleModule simpleModule = new SimpleModule().addSerializer(new JsonNodeExampleSerializer());
    Json.mapper().registerModule(simpleModule);
    if(nonNull(example)){
        stringExample = Json.pretty(example);
        //Remove cyclic dependency
        ObjectMapper objectMapper = new ObjectMapper();
        JsonNode jsonNode = null;
        try {
            jsonNode = objectMapper.readTree(stringExample);
        } catch (JsonProcessingException e) {
            throw new RuntimeException(e);
        }
        removeKey(jsonNode, pojo.toLowerCase());
        removeKey(jsonNode, "_links");
        stringExample = Json.pretty(jsonNode);
    }
    else{
        stringExample = Json.pretty(new HashMap<>() {{ put(pojo, "example_java_object");}});
    }
    if(nonNull(typeOfBodyParam) && typeOfBodyParam.equals("array")){
        return "["+stringExample+"]";
    }
    return stringExample;
  }

  private static Object getExampleForFormData(String dataType){
    if(dataType.equalsIgnoreCase("string")){
      return "example_string";
    }
    else if(dataType.toLowerCase().contains("int")){
      return 1;
    }
    else if(dataType.toLowerCase().contains("bool")){
        return true;
    }
    return "example_string";
  }

    private static String getArrayExampleForFormData(String dataType){
        if(dataType.equalsIgnoreCase("string")){
            return "[\"example_string\"]";
        }
        else if(dataType.toLowerCase().contains("int")){
            return "[1]";
        }
        else if(dataType.toLowerCase().contains("bool")){
            return "[true]";
        }
        return "[\"example_string\"]";
    }
  private static String mapToString(Map<String, Object> targetMap){
      SimpleModule simpleModule = new SimpleModule().addSerializer(new JsonNodeExampleSerializer());
      Json.mapper().registerModule(simpleModule);
      return Json.pretty(targetMap);
  }

    public static void removeKey(JsonNode json, String key) {
        if (json.isObject()) {
            json.fields().forEachRemaining(entry -> removeKey(entry.getValue(), key));
        }
        else if (json.isArray()) {
            json.forEach(element -> removeKey(element, key));
        }
        if(json.isObject()){
            ObjectNode objectNode = (ObjectNode) json;
            objectNode.remove(key);
        }
    }
}

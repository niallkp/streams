<#ftl output_format="XML" auto_esc=true>
<#--
  ~ Licensed to the Apache Software Foundation (ASF) under one
  ~ or more contributor license agreements.  See the NOTICE file
  ~ distributed with this work for additional information
  ~ regarding copyright ownership.  The ASF licenses this file
  ~ to you under the Apache License, Version 2.0 (the
  ~ "License"); you may not use this file except in compliance
  ~
  ~   http://www.apache.org/licenses/LICENSE-2.0
  ~
  ~ Unless required by applicable law or agreed to in writing,
  ~ software distributed under the License is distributed on an
  ~ "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  ~ KIND, either express or implied.  See the License for the
  ~ specific language governing permissions and limitations
  ~ under the License.
  -->
<#attempt>
    <#assign profile_information = pp.loadData('json', 'profile_information/profile_information.json')>
    <#recover>
        <#stop "NO_PROFILE_INFORMATION">
</#attempt>
@prefix : <${namespace}#> .
@prefix as: <http://www.w3.org/ns/activitystreams#> .
@prefix apst: <http://streams.apache.org/ns#> .
@prefix dc: <http://purl.org/dc/elements/1.1/#> .
@prefix dct: <http://purl.org/dc/terms/#> .
@prefix owl: <http://www.w3.org/2002/07/owl#> .
@prefix rdf: <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
@prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
@prefix vcard: <http://www.w3.org/2006/vcard/ns#> .
@base <${namespace}> .

<#-- profile_information/profile_information.json -->
<#if profile_information.profile.name?is_hash>
    <#assign fullname=profile_information.profile.name.full_name>
<#else>
    <#assign fullname=profile_information.profile.name>
</#if>
<#attempt>
    <#assign id=fullname?replace("\\W","","r")>
    <#recover>
        <#stop "NO_ID">
</#attempt>

:${id} a apst:FacebookProfile .

:${id}
<#if profile_information.profile.username??>
  as:displayName "${profile_information.profile.username!profile_information.profile.name.full_name!profile_information.profile.name}" ;
<#elseif profile_information.profile.name??>
    <#if profile_information.profile.name?is_hash>
    as:displayName "${profile_information.profile.name.full_name}" ;
    <#else>
    as:displayName "${profile_information.profile.name}" ;
    </#if>
</#if>
<#if profile_information.profile.name??>
    <#if profile_information.profile.name?is_hash>
    vcard:fn "${profile_information.profile.name.full_name}" ;
    <#else>
    vcard:fn "${profile_information.profile.name}" ;
    </#if>
</#if>
<#if profile_information.profile.name?is_hash>
  vcard:given-name "${profile_information.profile.name.first_name}" ;
  vcard:family-name "${profile_information.profile.name.last_name}" ;
</#if>
  dct:created "${profile_information.profile.registration_timestamp}" ;
  .

<#if profile_information.profile.emails??>
    <#list profile_information.profile.emails.emails![] as email>
:${id} vcard:email "mailto:${email}" .
    </#list>
</#if>

<#if profile_information.profile.phone_numbers??>
    <#assign telshash = {} />
    <#list profile_information.profile.phone_numbers![] as phone_number_obj>
        <#assign phone = pp.loadData('eval', '
        com.google.i18n.phonenumbers.PhoneNumberUtil phoneUtil = com.google.i18n.phonenumbers.PhoneNumberUtil.getInstance();
        String rawPhoneNumber = "${phone_number_obj.phone_number}";
        phoneNumber = phoneUtil.parse(rawPhoneNumber, "US");
        return phoneUtil.format(phoneNumber, com.google.i18n.phonenumbers.PhoneNumberUtil$PhoneNumberFormat.RFC3966);
      ')>
        <#assign telshash += { phone: phone } />
    </#list>
    <#list telshash?keys as tel>
:${id} vcard:tel "${tel}" .
    </#list>
</#if>

<#if profile_information.profile.address??>
:${id}
    <#if profile_information.profile.address.street??>
  vcard:street-address "${profile_information.profile.address.street}" ;
    </#if>
  vcard:locality "${profile_information.profile.address.city}" ;
  vcard:region "${profile_information.profile.address.region}" ;
  vcard:country-name "${profile_information.profile.address.country}" ;
    <#if profile_information.profile.address.zipcode??>
  vcard:postal-code "${profile_information.profile.address.zipcode}" ;
    </#if>
  .
</#if>

<#attempt>
    <#assign your_address_books = pp.loadData('json', 'about_you/your_address_books.json')>
    <#assign contacts = your_address_books.address_book.address_book>
    <#recover>
        <#assign contacts=[]>
</#attempt>

<#attempt>
    <#assign friends = pp.loadData('json', 'friends/friends.json')>
    <#recover>
</#attempt>

<#assign friendshash = {} />
<#if friends??>
    <#list friends.friends as friend>
        <#assign fid=friend.name?replace("\\W","","r") />
        <#if (fid?length > 0) >
            <#assign nameparts=friend.name?split(" ") />
            <#assign friendshash += { fid: nameparts } />
:${fid}
  a apst:FacebookProfile ;
  vcard:fn "${friend.name}" ;
  vcard:given-name "${nameparts[0]}" ;
            <#if (nameparts?size > 2)>
  vcard:additional-name "${nameparts[1]}" ;
  vcard:family-name "${nameparts[2]}" ;
            <#elseif  (nameparts?size == 2)>
  vcard:family-name "${nameparts[1]}" ;
            </#if>
            <#if contacts??>
                <#list contacts as contact>
                    <#if friend.name == contact.name>
                        <#assign telshash = {} />
                        <#list contact.details![] as detail>
                            <#if detail.contact_point??>
                                <#attempt>
                                    <#assign phone = pp.loadData('eval', '
                                        com.google.i18n.phonenumbers.PhoneNumberUtil phoneUtil = com.google.i18n.phonenumbers.PhoneNumberUtil.getInstance();
                                        String rawPhoneNumber = "${detail.contact_point}";
                                        phoneNumber = phoneUtil.parse(rawPhoneNumber, "US");
                                        return phoneUtil.format(phoneNumber, com.google.i18n.phonenumbers.PhoneNumberUtil$PhoneNumberFormat.RFC3966);
                                      ')>
                                    <#assign telshash += { phone: phone } />
                                    <#recover>
                                </#attempt>
                            </#if>
                        </#list>
                        <#list telshash?keys as tel>
:${id} vcard:tel "${tel}" .
                        </#list>
                    </#if>
                </#list>
            </#if>
  .

:${id}-connect-${fid}
  a as:Connect ;
  as:actor :${id} ;
  as:object :${fid} ;
  as:published "${friend.timestamp}" .

        </#if>
    </#list>
</#if>

<#if friends??>
    <#list friends.friends as friend>
        <#assign fid=friend.name?replace("\\W","","r")>
        <#assign nameparts=friend.name?split(" ")>
:${fid}
  a apst:FacebookProfile ;
  vcard:fn "${friend.name}" ;
  vcard:given-name "${nameparts[0]}" ;
        <#if (nameparts?size > 2)>
  vcard:additional-name "${nameparts[1]}" ;
  vcard:family-name "${nameparts[2]}" ;
        <#elseif (nameparts?size == 2)>
  vcard:family-name "${nameparts[1]}" ;
        </#if>
  .

:${id}-connect-${fid}
  a as:Connect ;
  as:actor :${id} ;
  as:object :${fid} ;
  as:published "${friend.timestamp}" .

    </#list>
</#if>

<#assign messagesDirs = pp.loadData('eval', '
  String[] dirs = new java.io.File(engine.getDataRoot(), "messages").list();
  return dirs;
')>

<#if messagesDirs??>
    <#if (messagesDirs?size > 0)>
        <#list messagesDirs as messageDir>
            <#attempt>
                <#assign messages = pp.loadData('json', 'messages/${messageDir}/message.json')>
                <#if (messages.participants?? && messages.participants?size == 1 && messages.title?? && messages.title?length > 0)>
                    <#assign fidraw = "${messages.title}">
                    <#assign fid=fidraw?replace("\\W","","r")>
                <#-- only keep the timestamps of direct messages with friends -->
                    <#if (fid?? && friendshash[fid]??)>
                        <#list messages.messages as message>
                            <#if fullname == message.sender_name>
:${id}-message-${fid}-${message.timestamp}
a as:Note ;
as:actor :${id} ;
as:object :${fid} ;
as:published "${message.timestamp}" .

                            <#else>
:${fid}-message-${id}-${message.timestamp}
a as:Note ;
as:actor :${fid} ;
as:object :${id} ;
as:published "${message.timestamp}" .

                            </#if>
                        </#list>
                    </#if>
                </#if>
                <#recover>
            </#attempt>
        </#list>
    </#if>
</#if>

select pcr.ref_num as "Chamado",
        /*CASE WHEN (pcr.type = 'R') THEN 'Solicitação'
        WHEN (pcr.type = 'I') THEN 'Incidente'
           ELSE 'N/D'
        END tipo,  */
        pc.sym as "ArvoreSistema",
        to_char(nvl((to_date('01-JAN-1970','DD-MON-RRRR') + ((pcr.open_date+(TO_NUMBER(SUBSTR(TZ_OFFSET(sessiontimezone),1,3))*60*60)) / (60 * 60 * 24))), null), 'DD/MM/YYYY hh24:mi:ss') as "DataInicio",
        to_char(nvl((to_date('01-JAN-1970','DD-MON-RRRR') + ((pcr.LAST_MOD_DT+(TO_NUMBER(SUBSTR(TZ_OFFSET(sessiontimezone),1,3))*60*60)) / (60 * 60 * 24))), null), 'DD/MM/YYYY hh24:mi:ss') as "DataMod",
        /*CASE WHEN (al.system_time is not null) THEN to_char((to_date('01-JAN-1970','DD-MON-RRRR') + ((system_time+(TO_NUMBER(SUBSTR(TZ_OFFSET(sessiontimezone),1,3))*60*60)) / (60 * 60 * 24))), 'DD/MM/YYYY hh24:mi:ss')
            WHEN (pcr.resolve_date is not null) THEN to_char((to_date('01-JAN-1970','DD-MON-RRRR') + ((pcr.resolve_date+(TO_NUMBER(SUBSTR(TZ_OFFSET(sessiontimezone),1,3))*60*60)) / (60 * 60 * 24))), 'DD/MM/YYYY hh24:mi:ss')
            ELSE to_char((to_date('01-JAN-1970','DD-MON-RRRR') + ((pcr.close_date+(TO_NUMBER(SUBSTR(TZ_OFFSET(sessiontimezone),1,3))*60*60)) / (60 * 60 * 24))), 'DD/MM/YYYY hh24:mi:ss')
        END Conclusao_Tarefa, */
        cc3.first_name||' '||cc3.middle_name as "Solicitante",
        cc2.first_name||' '||cc2.middle_name as "UsuarioAfetado",
        cc.first_name||' '||cc.middle_name as "AtribuidoPara",
        cc4.last_name as "Grupo",
        cs.sym as "Situacao",
        pcr.summary as "Titulo",
        pcr.description as "Descricao"
    from mdbadmin.Call_Req pcr,
        mdbadmin.prob_ctg pc,
        mdbadmin.ca_contact cc,
        mdbadmin.ca_contact cc2,
        mdbadmin.ca_contact cc3,
        mdbadmin.ca_contact cc4,
        mdbadmin.cr_stat cs,
        mdbadmin.ACT_LOG al
    where pc.persid = pcr.category
       and cc.contact_uuid(+) = pcr.assignee
       and cc2.contact_uuid(+) = pcr.customer
       and cc3.contact_uuid(+) = pcr.log_agent
       and cc4.contact_uuid(+) = pcr.group_id
       and cs.code = pcr.status
       and pcr.persid = al.call_req_id(+)
       and al.type(+) = 'AUTO_CL'
       and (
            -- Para cada ArvoreSistema definida nos Projetos que tiverem a propriedade HabilitarCASync igual a true, inserir uma linha abaixo + 'or'.
            -- Exemplo:
            REGEXP_SUBSTR(pc.sym, '[^.]+', 1, 1) like '#arvoresistema#'
           )
       and pcr.type = 'R' -- apenas as solicitações
       and cs.sym = 'Aberta' -- status Aberta
       and  cc4.last_name is not null -- com grupo definido
    order by pcr.open_date desc

#!/bin/bash

# Download SPARQL Integrate (if not already available)
[ -f si.jar ] || wget -O si.jar https://github.com/SmartDataAnalytics/SparqlIntegrate/releases/download/sparql-integrate-bundle-1.0.3-SNAPSHOT/sparql-integrate-bundle-1.0.3-SNAPSHOT-jar-with-dependencies.jar

# Download the IndeGx catalog of endpoints
[ -f indegx.ttl ] || wget -O indegx.ttl https://raw.githubusercontent.com/Wimmics/IndeGx/main/catalogs/all_catalog_edited.ttl
# Map each endpoint to its own named graph,
java -cp si.jar sparqlintegrate indegx.ttl 'PREFIX sd: <http://www.w3.org/ns/sparql-service-description#> PREFIX void: <http://rdfs.org/ns/void#> PREFIX dcat: <http://www.w3.org/ns/dcat#> CONSTRUCT { GRAPH ?o { ?s ?p ?o } } { ?s ?p ?x FILTER(?p = sd:endpoint || ?p = void:sparqlEndpoint || ?p = dcat:endpointURL ) BIND(IRI(REPLACE(STR(?x), "\\s+", "")) AS ?o) }' | \
# run the status check for each named graph in parallel
java -cp si.jar ngs map -t '5000,5000' --sparql status-check.sparql | \
java -cp si.jar sparqlintegrate --w=trig/pretty --u - 'PREFIX schema: <https://schema.org/> CONSTRUCT WHERE { ?s ?p ?o } ORDER BY ?s ?p ?o' > next-status.ttl
# and then merge the results

./diff-status.sh latest-status.ttl next-status.ttl > effective-status.ttl

mv effective-status.ttl latest-status.ttl



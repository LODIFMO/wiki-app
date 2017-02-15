class PagesController < ApplicationController
  def show
    redirect_to '/' if params[:keyword].blank?
    @keyword = params[:keyword]
    @description = load_descriptions.last
    @metaphacts = wikidata_metaphacts.first
  end

  private

  # get rus text from rdfs:comment
  def upload_rus(sparql)
    sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?concept ?description ?topic
        WHERE {
          ?concept rdfs:comment ?description .
          ?concept rdfs:label "#{params[:keyword]}"@en .
          ?topic foaf:primaryTopic ?concept .
          FILTER ( lang(?description) = "ru" )
        }
      SPARQL
    )
  end

  # get rus text from dbo:abstract
  def upload_rus_mod(sparql)
    sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?concept ?description ?topic
        WHERE {
          ?concept dbo:abstract ?description .
          ?concept rdfs:label "#{params[:keyword]}"@en .
          ?topic foaf:primaryTopic ?concept .
          FILTER ( lang(?description) = "ru" )
        }
      SPARQL
    )
  end

  # get eng text from rdfs:comment
  def upload_eng(sparql)
    sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?concept ?description ?topic
        WHERE {
          ?concept rdfs:comment ?description .
          ?concept rdfs:label "#{params[:keyword]}"@en .
          ?topic foaf:primaryTopic ?concept .
          FILTER ( lang(?description) = "en" )
        }
      SPARQL
    )
  end

  # get eng text from dbo:abstract
  def upload_eng_mod(sparql)
    sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?concept ?description ?topic
        WHERE {
          ?concept dbo:abstract ?description .
          ?concept rdfs:label "#{params[:keyword]}"@en .
          ?topic foaf:primaryTopic ?concept .
          FILTER ( lang(?description) = "en" )
        }
      SPARQL
    )
  end

  def load_descriptions
    sparql = SPARQL::Client.new("http://dbpedia.org/sparql")
    solutions = []
    solutions << upload_rus(sparql).first
    solutions << upload_rus_mod(sparql).first
    solutions << upload_eng(sparql).first
    solutions << upload_eng_mod(sparql).first
    solutions.sort_by {|x| x[:description].value.length}
  end

  def wikidata_metaphacts
    sparql = SPARQL::Client.new('https://wikidata.metaphacts.com/sparql')
    result = sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?uri ?label ?description WHERE {
          ?uri <http://www.w3.org/2000/01/rdf-schema#label> ?label.
          ?uri <http://schema.org/description> ?description.
          ?label <http://www.bigdata.com/rdf/search#search> "#{params[:keyword]}".
          ?label <http://www.bigdata.com/rdf/search#minRelevance> "0.5".
          ?label <http://www.bigdata.com/rdf/search#matchAllTerms> "true".
          BIND(<http://www.w3.org/2001/XMLSchema#integer>(SUBSTR(STR(?uri), 33 )) AS ?q)
        }
        ORDER BY ?q
        LIMIT 1
      SPARQL
    )
    result
  end
end

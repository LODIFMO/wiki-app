class PagesController < ApplicationController
  def show
    redirect_to '/' if params[:keyword].blank?
    @metaphacts = wikidata_metaphacts.first
    redirect_to '/' if @metaphacts[:label].blank?
    @keyword = correct_keyword.first[:label].value
    @engdescription = load_eng_description.last
    @rusdescription = load_rus_description.last
    @people = load_people
    @links = load_links
    @subjects = load_subjects
    @articles = load_articles
    @projects = load_projects
    make_json
  end

  private

  def make_json
    result = {
      name: 'owl:Thing',
      type: :class,
      children: [{
        name: 'ifmo:Keyword',
        type: :class,
        children: [
          {name: 'foaf:Person', type: :class, children:
            [{name: 'dbp:knownFor', type: :property},
             {name: 'dbo:almaMater', type: :property},
             {name: 'rdfs:label', type: :property},
             {name: 'dbo:nationality', type: :property}]},
          {name: 'foaf:Project', type: :class, children: [
            {name: 'rdfs:description', type: :property},
            {name: 'ou:startDate', type: :property},
            {name: 'ou:endDate', type: :property},
            {name: 'foaf:homepage', type: :property},
            {name: 'rdfs:label', type: :property},
            {name: 'dc:subject', type: :property}
          ]},
          {name: 'ifmo:Wikidata', type: :class, children: [
            {name: 'rdfs:description', type: :property},
            {name: 'rdfs:label', type: :property}
          ]},
          {name: 'ifmo:Subject', type: :class, children: [
            {name: 'rdfs:label', type: :property},
            {name: 'dct:subject', type: :property}
          ]},
          {name: 'ifmo:Link', type: :class, children: [
            {name: 'dbo:wikiPageExternalLink', type: :property},
            {name: 'rdfs:label', type: :property},
            {name: 'foaf:homepage', type: :property}
          ]},
          {name: 'bibo:Article', type: :class, children: [
            {name: 'dc:date', type: :property},
            {name: 'rdfs:description', type: :property},
            {name: 'rdfs:label', type: :property}
          ]},
          {name: 'rdfs:description', type: :property},
          {name: 'rdfs:label', type: :property},
          {name: 'foaf:homepage', type: :property},
          {name: 'foaf:primaryTopic', type: :property}
        ]
      }]
    }
    File.open("#{Rails.root}/public/#{@keyword.parameterize.underscore}.json", 'w') { |file| file.write result.to_json }
  end

  def load_projects
    sparql = SPARQL::Client.new('http://data.open.ac.uk/sparql')
    result = sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?think ?label ?start_date ?end_date ?homepage ?subject ?comment
        WHERE {
                  ?think <http://purl.org/dc/terms/description> ?description .
                  ?think <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> <http://vocab.ox.ac.uk/projectfunding#Project> .
                  ?think <http://www.w3.org/2000/01/rdf-schema#label> ?label .
                  OPTIONAL {
                      ?think <http://vocab.ox.ac.uk/projectfunding#startDate> ?start_date .
                  }
                  OPTIONAL {
                      ?think <http://vocab.ox.ac.uk/projectfunding#endDate> ?end_date .
                  }
                  OPTIONAL {
                      ?think <http://xmlns.com/foaf/0.1/homepage> ?homepage .
                  }
                  OPTIONAL {
                      ?think <http://purl.org/dc/terms/subject> ?subject_uri .
                      ?subject_uri <http://www.w3.org/2000/01/rdf-schema#label> ?subject .
                      FILTER ( lang(?subject) = "en" ) .
                  }
                  OPTIONAL {
                      ?think <http://www.w3.org/2000/01/rdf-schema#comment> ?comment .
                      FILTER ( lang(?comment) = "en" ) .
                  }
                  FILTER ( lang(?label) = "en" ) .
                  FILTER (regex(str(?description), "#{@keyword}", "i" ))
                }
        ORDER BY DESC(?start_date) DESC(?end_date) ?think
      SPARQL
    )
    result
  end

  def load_subjects
    sparql = SPARQL::Client.new('http://dbpedia.org/sparql')
    result = sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?concept ?subject ?label
        WHERE {
          ?concept rdfs:label "#{@keyword}"@en .
          OPTIONAL { ?concept dct:subject ?subject } .
          ?subject rdfs:label ?label .
          FILTER ( lang(?label) = "en" )
        }
      SPARQL
    )

    result
  end

  def load_links
    sparql = SPARQL::Client.new('http://dbpedia.org/sparql')
    result = sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?concept ?link ?title ?url
        WHERE {
          ?concept rdfs:label "#{@keyword}"@en .
          { 
            ?concept dbo:wikiPageExternalLink ?link
          } UNION {
            ?link dbp:genre ?concept
          }
          OPTIONAL {
            ?link rdfs:label ?title .
            FILTER ( lang(?title) = "en" ) .
            ?link foaf:homepage ?url
          }
        }
      SPARQL
    )

    result
  end

  # get rus text from rdfs:comment
  def upload_rus(sparql)
    sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?concept ?description ?topic ?homepage
        WHERE {
          ?concept rdfs:comment ?description .
          ?concept rdfs:label "#{@keyword}"@en .
          OPTIONAL { ?concept foaf:homepage ?homepage } .
          OPTIONAL { ?topic foaf:primaryTopic ?concept } .
          FILTER ( lang(?description) = "ru" )
        }
      SPARQL
    )
  end

  # get rus text from dbo:abstract
  def upload_rus_mod(sparql)
    sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?concept ?description ?topic ?homepage
        WHERE {
          ?concept dbo:abstract ?description .
          ?concept rdfs:label "#{@keyword}"@en .
          OPTIONAL { ?concept foaf:homepage ?homepage } .
          OPTIONAL { ?topic foaf:primaryTopic ?concept } .
          FILTER ( lang(?description) = "ru" )
        }
      SPARQL
    )
  end

  # get eng text from rdfs:comment
  def upload_eng(sparql)
    sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?concept ?description ?topic ?homepage
        WHERE {
          ?concept rdfs:comment ?description .
          ?concept rdfs:label "#{@keyword}"@en .
          OPTIONAL { ?concept foaf:homepage ?homepage } .
          OPTIONAL { ?topic foaf:primaryTopic ?concept } .
          FILTER ( lang(?description) = "en" )
        }
      SPARQL
    )
  end

  # get eng text from dbo:abstract
  def upload_eng_mod(sparql)
    sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?concept ?description ?topic ?homepage
        WHERE {
          ?concept dbo:abstract ?description .
          ?concept rdfs:label "#{@keyword}"@en .
          OPTIONAL { ?concept foaf:homepage ?homepage } .
          OPTIONAL { ?topic foaf:primaryTopic ?concept } .
          FILTER ( lang(?description) = "en" )
        }
      SPARQL
    )
  end

  def load_eng_description
    sparql = SPARQL::Client.new("http://dbpedia.org/sparql")
    solutions = []
    solutions << upload_eng(sparql).first
    solutions << upload_eng_mod(sparql).first
    solutions.sort_by {|x| x[:description].value.length}
  end

  def load_rus_description
    sparql = SPARQL::Client.new("http://dbpedia.org/sparql")
    solutions = []
    solutions << upload_rus(sparql).first
    solutions << upload_rus_mod(sparql).first
    solutions.sort_by {|x| x[:description].value.length}
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

  def load_people
    sparql = SPARQL::Client.new('http://dbpedia.org/sparql')
    result = sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?concept ?person ?person_name ?nationality_name
                (group_concat(distinct ?known_for ; separator = ";") AS ?known_for)
                ?university_name ?alma_mater
        WHERE {
          ?concept rdfs:label "#{@keyword}"@en .
          { ?person dbp:fields ?concept } UNION { ?person dbo:field ?concept } UNION { ?person dbo:knownFor ?concept } UNION { ?person dbp:field ?concept }
          OPTIONAL {
            ?person dbo:nationality ?nationality .
            ?nationality rdfs:label ?nationality_name .
            FILTER ( lang(?nationality_name) = "en" )
          }
          ?person rdfs:label ?person_name .
          FILTER ( lang(?person_name) = "en" ) .
          OPTIONAL {
            ?person dbp:knownFor ?known_for .
            FILTER ( lang(?known_for) = "en" )
          }
          OPTIONAL {
            ?person dbo:almaMater ?alma_mater .
            ?alma_mater rdfs:label ?university_name .
            FILTER ( lang(?university_name) = "en" )
          }
        }
      SPARQL
    )
    result
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

  def load_articles
    sparql = SPARQL::Client.new('http://data.open.ac.uk/sparql')
    result = sparql.query(
      <<-SPARQL
        SELECT DISTINCT ?think ?label ?date WHERE {
          ?think <http://purl.org/ontology/bibo/abstract> ?description .
          ?think <http://www.w3.org/2000/01/rdf-schema#label> ?label .
          ?think <http://purl.org/dc/terms/date> ?date .
          FILTER (regex(str(?description), "#{@keyword}", "i" ))
        }
        ORDER BY DESC(?date) ?think ?label
        LIMIT 30
      SPARQL
    )
    result
  end

  def correct_keyword
    sparql = SPARQL::Client.new('http://dbpedia.org/sparql')
    result = sparql.query(
      <<-SPARQL
        SELECT DISTINCT  ?label
        WHERE
          { ?concept  rdfs:label    ?label ;
                      rdf:type      owl:Thing
            FILTER ( lang(?label) = "en" )
            FILTER (lcase(str(?label)) = "#{params[:keyword].downcase}")
          }
        LIMIT 1
      SPARQL
    )
    result
  end
end

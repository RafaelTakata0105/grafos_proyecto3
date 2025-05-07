// Proyecto 3 - Minería de grafos

// Esteban Gomez Valerio
// Rafael Takata Garcia
// Roi Jared Flores Garza Stone

//En este caso, la fuente de datos que hemos elegido son los paises de Estados Unidos y Canada.
//Con el siguiente query podemos delimitar los aeropuertos a solo estos paises:
MATCH (n)
WHERE NOT n.country IN ['United States', 'Canada']
DETACH DELETE n

//Analisis del grafo
//Esquema general
CALL db.schema.visualization

//Contar los aeropuertos por país
MATCH(n:Airport)
RETURN n.country, COUNT(n) AS total_airports, COLLECT(n.Label) AS airport_names
ORDER BY total_airports DESC

//Total de relaciones
MATCH (a)-[r]->(b)
RETURN COUNT(r) AS total_relaciones

//gephi
MATCH (a)
SET a.latitude = toInteger(a.latitude)
SET a.longitude = toInteger(a.longitude)

//Creaciones del subgrafo
//Dirigido
CALL gds.graph.project(
    'myGraph',
    'Airport',
    {TO: {
        Properties: 'distance'
        }
    }
)

//Sin dirección
CALL gds.graph.project(
    'myGraphUndirected',
    'Airport',
    {TO: {
        Properties: 'distance',
        orientation:'UNDIRECTED'
        }
    }
)

//Reverso
CALL gds.graph.project(
    'myGraphReverse',
    'Airport',
    {TO: {
        Properties: 'distance',
        orientation:'REVERSE'
        }
    }
)


//Aplicación de los algoritmos

//Degree
CALL gds.degree.write('myGraphUndirected', { writeProperty: 'degree' })
YIELD centralityDistribution, nodePropertiesWritten
RETURN centralityDistribution.min AS minimumScore, centralityDistribution.mean AS meanScore, nodePropertiesWritten

//In_degree
CALL gds.degree.write('myGraph', { writeProperty: 'in_degree' })
YIELD centralityDistribution, nodePropertiesWritten
RETURN centralityDistribution.min AS minimumScore, centralityDistribution.mean AS meanScore, nodePropertiesWritten

//Out_degree
CALL gds.degree.write('myGraphReverse', { writeProperty: 'out_degree' })
YIELD centralityDistribution, nodePropertiesWritten
RETURN centralityDistribution.min AS minimumScore, centralityDistribution.mean AS meanScore, nodePropertiesWritten




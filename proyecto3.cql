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

//Gephi
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


//Aplicación de los algoritmos de degree

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

//Mejor camino desde Honolulu hasta Bethel
MATCH(source:Airport{Label:'Honolulu'}), (target:Airport{Label:'Bethel'})
CALL gds.shortestPath.dijkstra.write('myGraph',
{
sourceNode: source,
targetNode: target, 
relationshipWeightProperty: 'distance',
writeRelationshipType:'PATH_Hawaii_to_Alaska',
writeNodeIds: true,
writeCosts: true
})
YIELD relationshipsWritten
RETURN relationshipsWritten

//Buscar el camino
MATCH p=()-[r:PATH_Hawaii_to_Alaska]->() RETURN p

//Regresamos solo los nodos necesarios
MATCH(n:Airport)
WHERE id(n) IN [1838,1861,1765]
RETURN n

//¿Cual es el nodo con mayor degree?
MATCH(n:Airport)
RETURN n
ORDER by n.degree DESC
LIMIT 1

//Todos los caminos desde el nodo con mayor degree
MATCH(source:Airport{Label:'Chicago'})
CALL gds.allShortestPaths.delta.write('myGraph',
{
sourceNode: source,
relationshipWeightProperty: 'distance',
writeRelationshipType:'PATH_From_Chicago',
writeNodeIds: true,
writeCosts: true
})
YIELD relationshipsWritten
RETURN relationshipsWritten

//Mayor distance
MATCH (a)-[r:PATH_From_Chicago]->(oa) 
RETURN a.Label, r.totalCost, oa.Label
ORDER BY r.totalCost DESC
LIMIT 5

//Menor distance
MATCH (a)-[r:PATH_From_Chicago]->(oa) 
RETURN a.Label, r.totalCost, oa.Label
ORDER BY r.totalCost 
LIMIT 5

//Preguntas
//14)	Existe un pasajero Borracho con mucho dinero, sale del aeropuerto de Milwaukee 
//y solamente quiere seguir tomando en los aviones, por lo que compra vuelos aleatorios en los lugares 
//a donde llega, ¿hasta donde podría llegar después de 3 vuelos y que empiece a pegarle la cruda?

MATCH(a:Airport)
WHERE a.Label = 'Milwaukee'
WITH COLLECT(a) as sourceNodes
CALL gds.randomWalk.stream('myGraph',
{
    sourceNodes:sourceNodes,
    walkLength: 4,
    walksPerNode:1,
    randomSeed: 42,
    concurrency: 1
})
YIELD nodeIds, path
RETURN nodeIds, path
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

// 1) ¿Cuántas es la mayor cantidad de escalas que son necesarias para llegar de un aeropuerto a otro (diámetro del grafo)?
MATCH (a), (b)
WHERE a.Id <> b.Id
WITH a, b, shortestPath((a)-[*]-(b)) AS path
WHERE path IS NOT NULL // Contar solo los nodos con relaciones
RETURN length(path) AS diametro 
ORDER BY diametro DESC
LIMIT 1

// 2) ¿Cuántos aeropuertos se conectan con el de Atlanta, ya se directo o mediante otros aeropuertos?
MATCH(source:Airport{Label:'Atlanta'})
CALL gds.allShortestPaths.delta.write('myGraph',
{
    sourceNode: source,
    relationshipWeightProperty: 'distance',
    writeRelationshipType:
    'PATH_Atlanta_Directed', 
    writeNodeIds: true,
    writeCosts: true
})
YIELD relationshipsWritten
RETURN relationshipsWritten

// 3) ¿Cuál es la ruta más corta entre el aeropuerto de Toronto y el de Sacramento?
MATCH(source:Airport{Label:'Toronto'})
CALL gds.allShortestPaths.delta.write('myGraph',
{
    sourceNode: source,
    relationshipWeightProperty: 'distance',
    writeRelationshipType:
    'PATH_Toronto_Directed', 
    writeNodeIds: true,
    writeCosts: true
})
YIELD relationshipsWritten
RETURN relationshipsWritten

MATCH p=(v:Airport{Label:'Toronto'})-
[r:PATH_Toronto_Directed]->
(:Airport{Label:'Sacramento'})
RETURN p LIMIT 25

MATCH(n:Airport)
WHERE id(n) IN [125,1901,1878]
RETURN n

// 4) ¿Cuál es la ruta más corta entre el LA y el aeropuerto de Edmonton?
MATCH(source:Airport{Label:'Los Angeles'})
CALL gds.allShortestPaths.delta.write('myGraph',
{
    sourceNode: source,
    relationshipWeightProperty: 'distance',
    writeRelationshipType:
    'PATH_LA_Directed', 
    writeNodeIds: true,
    writeCosts: true
})
YIELD relationshipsWritten
RETURN relationshipsWritten

MATCH p=(v:Airport{Label:'Los Angeles'})-
[r:PATH_LA_Directed]->
(:Airport{Label:'Edmonton'})
RETURN p LIMIT 25

MATCH(n:Airport)
WHERE id(n) IN [1715,31]
RETURN n

// 5) ¿Cuál es el top 3 aeropuertos con mayor cantidad de vuelos recibidos?
MATCH (a:Airport)
RETURN a.Label as Aeropuerto, a.in_degree AS Entradas
ORDER BY Entradas DESC
LIMIT 3

// 6) ¿Cuál es el top 3 aeropuertos con mayor cantidad de vuelos enviados? 
MATCH (a:Airport)
RETURN a.Label as Aeropuerto, a.out_degree AS Salidas
ORDER BY Salidas DESC
LIMIT 3

// 7) ¿Cuál es el vuelo directo más corto en todo el grafo?
MATCH (a:Airport)-[r:TO]->(a2:Airport)
RETURN a.Label AS Salida, a2.Label AS Entrada, r.distance AS Distancia
ORDER BY Distancia ASC

// 8) ¿Cuál es el vuelo directo más largo en todo el grafo?
MATCH (a:Airport)-[r:TO]->(a2:Airport)
RETURN a.Label AS Salida, a2.Label AS Entrada, r.distance AS Distancia
ORDER BY Distancia DESC

// 9) ¿Qué aeropuertos fungen un papel critico en el flujo aéreo de Canada?
CALL gds.pageRank.write(
    'myGraph', 
    {
        writeProperty: 'PageRank', 
        maxIterations: 20, 
        dampingFactor: 0.85
    }
)
YIELD nodePropertiesWritten, ranIterations

MATCH(n:Airport)
WHERE n.country = 'Canada'
RETURN n.Label as Aeropuerto, n.PageRank as PageRank
Order By n.PageRank DESC

// 10) ¿Cuál es la menor distancia que se puede recorrer desde el aeropuerto de Miami hasta Quebec?
MATCH(source:Airport{Label:'Miami'}),
(target:Airport{Label:'Quebec'})
CALL gds.shortestPath.dijkstra.write('myGraph',
{
    sourceNode: source,
    targetNode: target,
    relationshipWeightProperty: 'distance',
    writeRelationshipType:'PATH_Miami_Quebec', 
    writeNodeIds: true,
    writeCosts: true
})
YIELD relationshipsWritten
RETURN relationshipsWritten

MATCH(n:Airport)
WHERE id(n) IN [1753,1854,65]
RETURN n

// 11) ¿Cuántos colores serían necesarios al aplicar el algoritmo de k1coloring?
CALL gds.k1coloring.write('myGraph', {writeProperty: 'Color'})
YIELD nodeCount, colorCount, ranIterations, didConverge

MATCH (a:Airport)
SET a.Color = a.Color + 1
// 26

// 13) ¿Cuántos aeropuertos existen sin conexiones a otros?
MATCH (n)
WHERE NOT EXISTS { MATCH (n)-[]-() }
RETURN n
// 1

// 14) Quiero hacer un recorrido por Estados Unidos, sin embargo quiero pasar por San Francisco, estoy dispuesto a realizar 5 viajes 
// ¿Qué ruta puedo seguir?
MATCH (a:Airport)
WHERE a.Label IN ['San Francisco'] AND a.country = 'United States'
WITH COLLECT(a) AS sourceNodes
CALL gds.randomWalk.stream(
 'myGraph',
 {
    sourceNodes: sourceNodes,
    walkLength: 5, 
    walksPerNode: 1,
    randomSeed: 42, 
    concurrency: 1
 }  
)
YIELD nodeIds, path
RETURN nodeIds, path
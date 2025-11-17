USE BD2_TPI_G15;
GO

------ VISTA 1 - Muestra una tabla de posiciones de los equipos de todas division en todas las temporadas
CREATE OR ALTER VIEW vista_tabla_posiciones_futbol AS
    SELECT E.idEquipo, E.nombre 'Equipo',L.idLiga, L.nombre 'Liga', T.anio,
        SUM(CASE 
                WHEN (P.idLocal = E.idEquipo AND P.golesLocal > P.golesVisitante and t.idTemporada = p.idTemporada) THEN 3
                WHEN (P.idVisitante = E.idEquipo AND P.golesVisitante > P.golesLocal and t.idTemporada = p.idTemporada) THEN 3
                WHEN (P.golesLocal = P.golesVisitante and t.idTemporada = p.idTemporada) THEN 1
                ELSE 0 
            END
        ) AS Puntos,
        SUM(
            CASE 
                WHEN P.idLocal = E.idEquipo AND P.idTemporada = T.idTemporada THEN P.golesLocal
                WHEN P.idVisitante = E.idEquipo AND P.idTemporada = T.idTemporada THEN P.golesVisitante
                ELSE 0
            END
        ) AS 'Goles a Favor',
        SUM(
            CASE 
                WHEN P.idLocal = E.idEquipo AND P.idTemporada = T.idTemporada THEN P.golesVisitante
                WHEN P.idVisitante = E.idEquipo AND P.idTemporada = T.idTemporada THEN P.golesLocal
                ELSE 0
            END
        ) AS 'Goles en Contra',
        COUNT(CASE WHEN P.idTemporada = T.idTemporada THEN 1 END) AS 'Partidos Jugados'
    FROM equipo E
    INNER JOIN liga L ON L.idLiga = E.idLiga
    INNER JOIN Temporada T ON T.idLiga = E.idLiga
    LEFT JOIN Partido P ON E.idEquipo IN (P.idLocal,P.idVisitante)
    GROUP BY E.idEquipo, E.nombre,L.idLiga, L.nombre, T.anio

GO
------ VISTA 2 - Muestra las estadistica de los jugadores durante su carrera
CREATE OR ALTER VIEW vista_estadisticas_jugadores_futbol AS
    SELECT 
        J.idJugador,
        J.nombre + ' ' + J.apellido AS 'Nombre completo',
        E.nombre AS 'Equipo',
        P.idLiga AS 'Id Liga',
        L.nombre AS 'Liga',
        COUNT(CASE WHEN EPJ.minutos > 0 THEN 1 END) AS 'Partidos Jugados',
        SUM (EPJ.minutos) 'Minutos',
        SUM(EPJ.goles) AS 'Goles',
        SUM(EPJ.asistencias) AS 'Asistencias',
        SUM(EPJ.tarjetasAmarillas) AS 'Tarjetas Amarillas',
        SUM(EPJ.tarjetasRojas) AS 'Tarjetas Rojas'
    FROM Jugador J
    INNER JOIN Equipo E ON E.idEquipo = J.idEquipo
    INNER JOIN Liga L ON L.idLiga = E.idLiga
    INNER JOIN Partido P ON (
        E.idEquipo IN (P.idLocal, P.idVisitante)
        AND P.idLiga = L.idLiga
    )
    INNER JOIN EstadisticasxPartidoxJugador EPJ ON EPJ.idJugador = J.idJugador AND EPJ.idPartido = P.idPartido
    GROUP BY J.idJugador, J.nombre, J.apellido, E.nombre, P.idLiga, L.nombre;
GO

------ VISTA 3 - Muestra el historial de campeones de todas las temporadas
CREATE OR ALTER VIEW view_Historial_Campeones AS
    SELECT 
        L.IdLiga AS IdLiga,
        L.nombre AS Liga,
        T.anio AS Temporada,
        E1.nombre AS Campeon,
        E2.nombre AS Subcampeon,
        H.puntosCampeon AS Puntos,
        H.victoriasCampeon AS Victorias
    FROM Historial H
    INNER JOIN Liga L ON L.idLiga = H.idLiga
    INNER JOIN Temporada T ON T.idTemporada = H.idTemporada
    INNER JOIN Equipo E1 ON E1.idEquipo = H.idCampeon
    INNER JOIN Equipo E2 ON E2.idEquipo = H.idSubcampeon;
GO

------ VISTA 4 - Muestra el rendimiento promedio de los equipos en las temporadas
CREATE OR ALTER VIEW vista_rendimientoPorLiga AS
    SELECT 
        L.nombre AS Liga, 
        E.nombre AS Equipo, 
        P.partidosTotales, 
        P.puntosTotales, 
        P.promedio
    FROM Promedio P
    INNER JOIN Equipo E ON E.idEquipo = P.idEquipo
    INNER JOIN Liga L ON L.idLiga = P.idLiga

GO

------ VISTA 5 - Muestra los jugadores con más goles acumulados
CREATE OR ALTER VIEW vista_goleadores AS
SELECT 
    J.nombre + ' ' + J.apellido AS Jugador,
    E.nombre AS Equipo,
    SUM(EPJ.goles) AS "Goles Totales"
FROM EstadisticasxPartidoxJugador EPJ
INNER JOIN Jugador J ON J.idJugador = EPJ.idJugador
INNER JOIN Equipo E ON E.idEquipo = J.idEquipo
GROUP BY J.Nombre, J.apellido, E.Nombre;

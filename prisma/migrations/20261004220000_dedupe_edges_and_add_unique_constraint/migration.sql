-- The same reading was being inserted repeatedly: a packet is gated to MQTT by every gateway that
-- hears it, and a flooded packet can be re-heard many times over. createMany's `skipDuplicates`
-- was already set, but it only skips rows that would violate a unique constraint, and there was
-- none on the data columns - so it never skipped anything.

-- Drop the redundant copies, keeping the earliest row for each distinct reading.
DELETE e FROM `edges` e
INNER JOIN (
    SELECT MIN(id) AS keep_id, from_node_id, to_node_id, packet_id, source
    FROM `edges`
    GROUP BY from_node_id, to_node_id, packet_id, source
    HAVING COUNT(*) > 1
) d
  ON  e.from_node_id = d.from_node_id
  AND e.to_node_id   = d.to_node_id
  AND e.packet_id    = d.packet_id
  AND e.source       = d.source
  AND e.id          <> d.keep_id;

-- Now the constraint can be added, which makes skipDuplicates actually work from here on.
CREATE UNIQUE INDEX `edges_from_node_id_to_node_id_packet_id_source_key`
    ON `edges`(`from_node_id`, `to_node_id`, `packet_id`, `source`);

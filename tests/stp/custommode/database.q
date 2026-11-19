// Schema for this suite: it needs these five tables whatever the application's own schema file defines
quote:([]time:`timestamp$(); sym:`g#`symbol$(); bid:`float$(); ask:`float$(); bsize:`long$(); asize:`long$(); mode:`char$(); ex:`char$(); src:`symbol$())
trade:([]time:`timestamp$(); sym:`g#`symbol$(); price:`float$(); size:`int$(); stop:`boolean$(); cond:`char$(); ex:`char$();side:`symbol$())
quote_iex:([]time:`timestamp$(); sym:`g#`symbol$(); bid:`float$(); ask:`float$(); bsize:`long$(); asize:`long$(); mode:`char$(); ex:`char$(); srctime:`timestamp$())
trade_iex:([]time:`timestamp$(); sym:`g#`symbol$(); price:`float$(); size:`int$(); stop:`boolean$(); cond:`char$(); ex:`char$(); srctime:`timestamp$())
heartbeat:([]time:`timestamp$(); sym:`symbol$(); procname:`symbol$(); counter:`long$(); pid:`int$(); host:`$(); port:`int$())

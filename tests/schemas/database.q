// Schema for this suite: the Starter Pack's three tables and the two _iex tables the checks expect, whatever the application's own schema file defines
quote:([]time:`timestamp$(); sym:`g#`symbol$(); bid:`float$(); ask:`float$(); bsize:`long$(); asize:`long$(); mode:`char$(); ex:`char$(); src:`symbol$())
trade:([]time:`timestamp$(); sym:`g#`symbol$(); price:`float$(); size:`int$(); stop:`boolean$(); cond:`char$(); ex:`char$();side:`symbol$())
packets:([] time:`timestamp$(); sym:`symbol$(); src:`symbol$(); dest:`symbol$(); srcport:`long$(); destport:`long$(); seq:`long$(); ack:`long$(); win:`long$(); tsval:`long$(); tsecr:`long$(); flags:(); protocol:`symbol$(); length:`long$(); len:`long$(); data:())
quote_iex:([]time:`timestamp$(); sym:`g#`symbol$(); bid:`float$(); ask:`float$(); bsize:`long$(); asize:`long$(); mode:`char$(); ex:`char$(); srctime:`timestamp$())
trade_iex:([]time:`timestamp$(); sym:`g#`symbol$(); price:`float$(); size:`int$(); stop:`boolean$(); cond:`char$(); ex:`char$(); srctime:`timestamp$())

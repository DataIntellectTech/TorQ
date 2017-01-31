[ Creating a Custom Application ]( http://www.aquaq.co.uk/q/torq-packaging/ )

Something that is not immediately clear is how a custom application built on TorQ should be structured and deployed. This blog outlines how a custom application should be structured.

[ Avoiding End-of-Day Halts ]( http://www.aquaq.co.uk/q/avoiding-end-of-day-halts-with-torq/ )

kdb+tick is great, but there’s a problem- when the RDB (real time database) writes to disk on its daily schedule, users cannot access that day’s data until the write out is complete. this blog post details how TorQ solves this problem.

[ Fast, Flexible, Low Memory End-Of-Day Writes ]( http://www.aquaq.co.uk/q/optional-write-down-method-added-to-wdb-process-in-torq-2-3/ )

A discussion on which method you should use for an end-of-day sort in TorQ.

[ End-of-Day Parallel Sorting ]( http://www.aquaq.co.uk/q/end-of-day-parallel-sorting-in-torq/ )

Details on how TorQ utilises sortslaves to vastly speed up the end-of-day sort.

[ Broadcast Publish ]( http://www.aquaq.co.uk/q/kdb-3-4-broadcast-publish/ )

kdb+ v3.4 introduces a new broadcast feature that reduces the work done when publishing messages to multiple subscribers. This blog post explains how and why to use this feature.

[ Recovering Corrupt Tickerplant Logs ]( http://www.aquaq.co.uk/q/recovering-corrupt-tickerplant-logs/ )

Corrupt tickerplant logs are a curse that no one deserves but that doesn’t stop them from happening even to the best of us. However, all hope is not lost as it is possible to recover the good messages and discard the bad. In this post we will extend upon the standard rescuelog procedure to recover as much as possible from the log file.

[ kdb+ Gateways ]( http://www.aquaq.co.uk/q/kdb-gateways/ )

The advantages and methods of using a gateway in a kdb+ tick system.

[ Faster Recovery With kdb+ tick ]( http://www.aquaq.co.uk/q/faster-recovery-with-kdb-tick/ )

How to effectively recover a process to its previous state after a crash using the RDB instead of the tickerplant log.

[ Parallel kdb+ Database Access with QPad ]( http://www.aquaq.co.uk/q/parallel-database-access-with-qpad-and-torq-kdb/ )

We’ve been working with Oleg Zakharov, who created QPad, to implement asynchronous querying and allow users to run multiple concurrent queries more efficiently. This blog explains how it works.

[ TorQ Permission Framework ]( http://www.aquaq.co.uk/q/torq-permission-framework/ )

An in depth and interactive post explaining TorQ permissioning.

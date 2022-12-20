# DOSP-Gossip-Algorithm
Developed as Part of Coursework for COP5615 - Distributed Operating Systems

Programming Language: Erlang

https://user-images.githubusercontent.com/47007121/208554145-27140732-4f76-470a-860f-e1d98cdd1082.mp4

Description
Actor Model
The actors are spawned in the 85th line of the code and after that work is assigned to them by the server.

Topology
Full - All the nodes are connected to each other and the random loop function picks the random node to share the rumor or push sum.

Line - The Neighbor Map keeps the track of the nodes that a node is allowed to share gossip or push sum and picks a random node from them. The neighbors are created using the Up and Down function for the nodes above and below it. Random Function selects the neighbor.

2D Grid -  The Neighbor Map keeps the track of the nodes that a node is allowed to share gossip or push sum and picks a random node from them. The neighbors are created using the North, South, East and West functions for the nodes above and below it. Works for perfect squares. 

Imperfect 3D Grid - The Neighbor Map keeps the track of the nodes that a node is allowed to share gossip or push sum and picks a random node from them. The neighbors are created using the North, South, East, and West functions for the nodes above and below it along with assigned to create 3D structure. The Plane Size and RowSize according to the input need to be added in lines 47 and 46. For e.g. for 8 nodes Plane size=4 and row =2 because Erlang does not have a cube root function 

Gossip Algorithm
The gossip algorithm works parallelly or concurrently. Each node is part of the network in case of full. For line, 2d and imp3d a separate map is maintained that contains the PID’s of the neighbor nodes or the nodes that are allowed to communicate with each other. The random loop picks or selects a random node from which the rumor is sent. A Rumour map keeps track of how many times a node has heard the rumor. As soon as the node hears a rumor 10 times it moves to the finished list and is no more an active participant. In the case of line, 2d, and imp3d the neighbor map is also updated for the active nodes that are ready to receive. We terminate the algorithm after convergence and measure the time taken to run the algorithm.

Push Sum
The push algorithm works parallelly or concurrently. Each node is part of the network in case of full. For line, 2d and imp3d a separate map is maintained that contains the PID’s of the neighbor nodes or the nodes that are allowed to communicate with each other. The random loop picks or selects a random node from which the rumor is sent. A Weights map keeps track of sum, weight, and s/w. The node converges when the s/w ratio present at each node does not change more than 10 ^ -10 even after three rounds. In the case of line, 2d, and imp3d the neighbor map is also updated for the active nodes that are ready to receive. We terminate the algorithm after convergence and measure the time taken to run the algorithm

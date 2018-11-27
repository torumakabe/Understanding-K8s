#!/bin/bash

context=$(kubectl config current-context)

cluster=$(kubectl config view -o jsonpath='{.contexts[?(@.name == "'$context'")].context.cluster}')
user=$(kubectl config view -o jsonpath='{.contexts[?(@.name == "'$context'")].context.user}')

kubectl config delete-context $context
kubectl config delete-cluster $cluster
kubectl config unset users.${user}
library(readxl)
library(MASS)
library(randomForest)
library(pROC)
library(Metrics)

# 讀取資料
data = read.csv("your_path/Bank/train.csv", encoding = "UTF-8")

# 檢查資料集結構
str(data)

# 確保目標變數為分類變數
data$Exited <- as.factor(data$Exited)

# 設定亂數種子
set.seed(1111)

# 拆分資料集為訓練集和驗證集
sample_index <- sample(1:nrow(data), size = 0.8 * nrow(data))
train_data <- data[sample_index, ]
validation_data <- data[-sample_index, ]

# 計算√p變數數量
p <- ncol(train_data) - 1 # 減去一個目標變數
mtry_value <- floor(sqrt(p))

# 設置500 棵樹
rf.model <- randomForest(Exited ~ ., data = train_data, mtry = mtry_value, ntree = 500)

# 打印模型信息
print(rf.model)

# 獲取和打印具體參數
num_trees <- rf.model$ntree
num_variables <- rf.model$mtry
tree_depths <- rf.model$forest$ndbigtree  # 各樹的節點數
min_node_size <- rf.model$nodesize

print(paste("Number of trees:", num_trees))
print(paste("Number of variables tried at each split (mtry):", num_variables))
print(paste("Minimum node size:", min_node_size))
print("Tree depths (number of nodes in each tree):")
print(tree_depths)
# 在驗證集上進行預測
predictions <- predict(rf.model, validation_data)

# 計算混淆矩陣
confusion_matrix <- table(validation_data$Exited, predictions)
print(confusion_matrix)

# 計算正確率
test_accuracy <- sum(diag(confusion_matrix)) / sum(confusion_matrix)
print(test_accuracy)

# 預測概率
pred_prob <- predict(rf.model, validation_data, type = "prob")[,2]

# 計算ROC對象和AUC
roc_obj <- roc(validation_data$Exited, pred_prob)
auc_value <- roc_obj$auc
print(paste("AUC:", auc_value))

# 繪製ROC曲線
plot(roc_obj, main = "ROC Curve", col = "black", lwd = 2)
abline(a = 0, b = 1, lty = 2, col = "red")

# 計算變數重要性
importance_values <- importance(rf.model)
print(importance_values)

# 繪製變數重要性圖
varImpPlot(rf.model, main = "Variable Importance Plot")

# 計算每棵樹的最大深度
get_tree_depth <- function(tree) {
  left_daughter <- tree[,"left daughter"]
  right_daughter <- tree[,"right daughter"]
  
  depth <- rep(0, nrow(tree))
  for (i in seq_len(nrow(tree))) {
    if (left_daughter[i] != 0) {
      depth[left_daughter[i]] <- depth[i] + 1
      depth[right_daughter[i]] <- depth[i] + 1
    }
  }
  return(max(depth))
}

max_depths <- sapply(1:rf.model$ntree, function(k) {
  tree <- getTree(rf.model, k = k, labelVar = TRUE)
  get_tree_depth(tree)
})

# 打印最大深度
print(max_depths)
max_depth <- max(max_depths)
print(paste("Maximum tree depth in the forest:", max_depth))

